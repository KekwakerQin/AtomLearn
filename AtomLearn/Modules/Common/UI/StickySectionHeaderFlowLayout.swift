import UIKit

final class StickySectionHeaderFlowLayout: UICollectionViewFlowLayout {
    var stickySection: Int = 0

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attrs = super.layoutAttributesForElements(in: rect),
              let collectionView else { return super.layoutAttributesForElements(in: rect) }

        let contentOffsetY = collectionView.contentOffset.y + collectionView.adjustedContentInset.top

        for attr in attrs where attr.representedElementKind == UICollectionView.elementKindSectionHeader {
            guard attr.indexPath.section == stickySection else { continue }

            var frame = attr.frame
            frame.origin.y = max(contentOffsetY, frame.origin.y)
            attr.frame = frame
            attr.zIndex = 1024
        }

        return attrs
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        true
    }
}
