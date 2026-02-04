import UIKit

final class StickySectionHeaderFlowLayout: UICollectionViewFlowLayout {

    var stickySection: Int = 0

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let collectionView else { return super.layoutAttributesForElements(in: rect) }

        let superAttrs = super.layoutAttributesForElements(in: rect) ?? []
        var attrs = superAttrs.compactMap { $0.copy() as? UICollectionViewLayoutAttributes }

        // Если sticky header не попал в rect — добавляем его вручную
        let stickyIndexPath = IndexPath(item: 0, section: stickySection)
        let hasSticky = attrs.contains {
            $0.representedElementKind == UICollectionView.elementKindSectionHeader &&
            $0.indexPath == stickyIndexPath
        }

        if !hasSticky,
           let headerAttr = super.layoutAttributesForSupplementaryView(
            ofKind: UICollectionView.elementKindSectionHeader,
            at: stickyIndexPath
           )?.copy() as? UICollectionViewLayoutAttributes {
            attrs.append(headerAttr)
        }

        // Липнем только сверху: без нижних лимитов
        let topY = collectionView.contentOffset.y + collectionView.adjustedContentInset.top

        for attr in attrs where attr.representedElementKind == UICollectionView.elementKindSectionHeader {
            guard attr.indexPath.section == stickySection else { continue }

            var frame = attr.frame
            frame.origin.y = max(topY, frame.origin.y)
            attr.frame = frame
            attr.zIndex = 1024
        }

        return attrs
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        true
    }
}
