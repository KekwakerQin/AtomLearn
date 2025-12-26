import FirebaseFirestore

extension CreateBoardInput {

    func toFirestore(ownerUID: String) -> [String: Any] {
        var data: [String: Any] = [
            "title": title,
            "description": description ?? "",
            "subject": subject,
            "lang": lang,
            "tags": tags,
            "visibility": visibility.rawValue,
            "ownerUID": ownerUID,
            "learningIntent": learningIntent.rawValue,
            "repetitionModel": repetitionModel.rawValue,
            "createdAt": FieldValue.serverTimestamp(),
            "lastActivityAt": FieldValue.serverTimestamp()
        ]

        if let examDate {
            data["examDate"] = Timestamp(date: examDate)
        }

        return data
    }
}
