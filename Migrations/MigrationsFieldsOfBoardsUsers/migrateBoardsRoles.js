/**
 * ================================
 * Firestore Migration: Boards v1 → v2
 * ================================
 *
 * Цель:
 * Денормализовать роли участников доски из сабколлекции
 * `boards/{boardId}/collaborators` в сам документ board.
 *
 * Новые поля в `boards/{boardId}`:
 * - editorUIDs: string[]   // пользователи с правом редактирования
 * - viewerUIDs: string[]   // пользователи с правом просмотра (на будущее)
 * - memberUIDs: string[]   // все участники доски (для быстрых выборок)
 *
 * Зачем:
 * - Быстрые проверки прав доступа (owner/editor)
 * - Упрощение Firestore Rules
 * - Быстрый список бордов пользователя (BoardList)
 *
 * Viewer:
 * - Сейчас не используется активно
 * - Добавлен для будущего расширения ролей
 *
 * Версионирование:
 * - schemaVersion: 2
 * - migratedAt: serverTimestamp
 *
 * Запуск:
 *   node migrateBoardsRoles.js
 *   DRY_RUN=1 node migrateBoardsRoles.js
 */

// ================================
// Imports & Firebase initialization
// ================================
const admin = require("firebase-admin");
const path = require("path");

const SERVICE_ACCOUNT_PATH = path.join(__dirname, "serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(require(SERVICE_ACCOUNT_PATH)),
});

const db = admin.firestore();

// ================================
// Migration configuration
// ================================
const BOARDS_COLLECTION = "boards";
const COLLAB_SUBCOLLECTION = "collaborators";

// Версия схемы, к которой приводим документы
const TARGET_SCHEMA_VERSION = 2;

// DRY_RUN=1 → только логируем, без записи в БД
const DRY_RUN = process.env.DRY_RUN === "1";

// Ограничение на количество документов за запуск
// Полезно для безопасных прод-запусков
const LIMIT_PER_RUN = 0; // 0 = без ограничений

// Optional: migrate only boards that aren't migrated yet
const ONLY_NOT_MIGRATED = false;

// Firestore batch limit = 500
const MAX_BATCH_OPS = 450;

// ================================
// Helper utilities
// ================================

/**
 * Нормализует роль из collaborators.
 * Защищает от мусорных значений.
 */
function normalizeRole(role) {
  if (!role) return null;
  const r = String(role).toLowerCase();
  if (r === "editor") return "editor";
  if (r === "viewer") return "viewer";
  if (r === "owner") return "owner";
  return null;
}

// ================================
// Per-document migration logic
// ================================

/**
 * Мигрирует один board-документ к TARGET_SCHEMA_VERSION.
 * Возвращает:
 * - skipped: true  → если миграция не требуется
 * - updatePayload → данные для записи
 */
async function migrateBoard(boardDoc) {
  const boardId = boardDoc.id;
  const boardData = boardDoc.data() || {};

  const ownerUID = boardData.ownerUID || null;

  // Читаем сабколлекцию collaborators
  const collabsSnap = await db
    .collection(BOARDS_COLLECTION)
    .doc(boardId)
    .collection(COLLAB_SUBCOLLECTION)
    .get();

  const editors = new Set();
  const viewers = new Set();
  const members = new Set();

  // owner всегда участник доски
  if (ownerUID) members.add(ownerUID);

  collabsSnap.forEach((c) => {
    const uid = c.id; 
    const role = normalizeRole(c.get("role"));

    // любой collaborator = участник
    members.add(uid);

    if (role === "editor") editors.add(uid);
    if (role === "viewer") viewers.add(uid);

    // if role is owner, we ignore putting into arrays
    // because owner is stored as ownerUID
  });

  // owner не должен дублироваться в ролях
  if (ownerUID) {
    editors.delete(ownerUID);
    viewers.delete(ownerUID);
  }

  const editorUIDs = Array.from(editors);
  const viewerUIDs = Array.from(viewers);
  const memberUIDs = Array.from(members);

  // Если документ уже в нужной версии — пропускаем
  const alreadyV2 = boardData.schemaVersion === TARGET_SCHEMA_VERSION;
  if (alreadyV2) {
    // You can decide to re-run anyway; often safe to skip to reduce writes
    return { boardId, skipped: true, editorUIDs, viewerUIDs, memberUIDs };
  }

  const updatePayload = {
    editorUIDs,
    viewerUIDs,
    memberUIDs,
    schemaVersion: TARGET_SCHEMA_VERSION,
    migratedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  return { boardId, skipped: false, updatePayload, editorUIDs, viewerUIDs, memberUIDs };
}

// ================================
// Migration runner
// ================================
async function main() {
  console.log("=== Firestore migration started ===");
  console.log("DRY_RUN:", DRY_RUN);

  const projectId = admin.app().options.projectId;
console.log("Connected projectId:", projectId);

const collections = await db.listCollections();
console.log("Top-level collections:", collections.map(c => c.id));

let query = db.collection(BOARDS_COLLECTION);

  // If inequality query causes index issues, comment it and use:
  // query = db.collection(BOARDS_COLLECTION);

  const snap = await query.get();

  const docs = snap.docs;
  console.log("Boards fetched:", docs.length);

  let processed = 0;
  let updated = 0;
  let skipped = 0;
  let batch = db.batch();
  let batchOps = 0;

  for (const doc of docs) {
    if (LIMIT_PER_RUN > 0 && processed >= LIMIT_PER_RUN) break;

    processed++;

    const result = await migrateBoard(doc);

    if (result.skipped) {
      skipped++;
      continue;
    }

    updated++;

    if (DRY_RUN) {
        console.log(`[DRY] board=${result.boardId}`, result.updatePayload);
        continue;
    }

    const ref = db.collection(BOARDS_COLLECTION).doc(result.boardId);
    batch.set(ref, result.updatePayload, { merge: true });
    batchOps++;

    if (batchOps >= MAX_BATCH_OPS) {
      console.log(`Committing batch (${batchOps} ops)...`);      await batch.commit();
      batch = db.batch();
      batchOps = 0;
    }

    if (processed % 50 === 0) {
      console.log(
        `Progress: processed=${processed}, updated=${updated}, skipped=${skipped}`
      );
    }
  }

  if (!DRY_RUN && batchOps > 0) {
    console.log(`Committing final batch (${batchOps} ops)...`);
    await batch.commit();
  }

  console.log("=== Migration finished ===");
  console.log({ processed, updated, skipped });
}

main().catch((e) => {
  console.error("Migration failed:", e);
  process.exit(1);
});
