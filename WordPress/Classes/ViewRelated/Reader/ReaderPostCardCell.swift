import Foundation

@objc public protocol ReaderPostCellDelegate: NSObjectProtocol
{
    func readerCell(cell: ReaderPostCardCell, commentActionForProvider provider: ReaderPostContentProvider)
    func readerCell(cell: ReaderPostCardCell, likeActionForProvider provider: ReaderPostContentProvider)
    func readerCell(cell: ReaderPostCardCell, viewActionForProvider provider: ReaderPostContentProvider)
    func readerCell(cell: ReaderPostCardCell, menuActionForProvider provider: ReaderPostContentProvider, fromView sender: UIView)
}

enum CardAction: Int
{
    case Comment = 1
    case Like
    case View
}

@objc public class ReaderPostCardCell: UITableViewCell
{
    // MARK - Properties

    @IBOutlet private weak var innerContentView: UIView!
    @IBOutlet private weak var cardContentView: UIView!
    @IBOutlet private weak var cardBorderView: UIView!
    @IBOutlet private weak var headerView: UIView!
    @IBOutlet private weak var avatarImageView: UIImageView!
    @IBOutlet private weak var blogNameLabel: UILabel!
    @IBOutlet private weak var bylineLabel: UILabel!
    @IBOutlet private weak var menuButton: UIButton!

    @IBOutlet private weak var featuredImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var summaryLabel: UILabel!
    @IBOutlet private weak var tagLabel: UILabel!

    @IBOutlet private weak var actionButtonRight: UIButton!
    @IBOutlet private weak var actionButtonCenter: UIButton!
    @IBOutlet private weak var actionButtonLeft: UIButton!
    @IBOutlet private weak var actionButtonFlushLeft: UIButton!

    @IBOutlet private weak var featuredImageHeightContraint: NSLayoutConstraint!
    @IBOutlet private weak var featuredImageBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var titleLabelBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var summaryLabelBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var tagLabelBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var actionButtonViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var actionButtonViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var cardContentBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var maxIPadWidthConstraint: NSLayoutConstraint!

    public weak var delegate: ReaderPostCellDelegate?
    public weak var contentProvider: ReaderPostContentProvider?

    private var featuredImageHeightConstraintConstant: CGFloat = 0.0
    private var featuredImageBottomConstraintConstant: CGFloat = 0.0
    private var titleLabelBottomConstraintConstant: CGFloat = 0.0
    private var summaryLabelBottomConstraintConstant: CGFloat = 0.0
    private var tagLabelBottomConstraintConstant: CGFloat = 0.0

    // MARK - Accessors

    public override var backgroundColor: UIColor? {
        didSet{
            contentView.backgroundColor = backgroundColor
            innerContentView.backgroundColor = backgroundColor
        }
    }

    public override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        setHighlighted(selected, animated: animated)
    }

    public override func setHighlighted(highlighted: Bool, animated: Bool) {
        let previouslyHighlighted = highlighted
        super.setHighlighted(highlighted, animated: animated)

        if previouslyHighlighted == highlighted {
            return
        }
        applyHighlightedEffect(highlighted, animated: animated)
    }


    // MARK - Lifecycle Methods

    public override func awakeFromNib() {
        super.awakeFromNib()
        featuredImageHeightConstraintConstant = featuredImageHeightContraint.constant
        featuredImageBottomConstraintConstant = featuredImageBottomConstraint.constant
        titleLabelBottomConstraintConstant = titleLabelBottomConstraint.constant
        summaryLabelBottomConstraintConstant = summaryLabelBottomConstraint.constant
        tagLabelBottomConstraintConstant = tagLabelBottomConstraint.constant
        applyStyles()
    }

    /**
        Ignore taps in the card margins
    */
    public override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        if (!CGRectContainsPoint(cardContentView.frame, point)) {
            return nil
        }
        return super.hitTest(point, withEvent: event)
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        applyHighlightedEffect(false, animated: false)
    }

    public override func sizeThatFits(size: CGSize) -> CGSize {
        let innerWidth = innerWidthForSize(size)
        let innerSize = CGSizeMake(innerWidth, CGFloat.max)

        var height = CGRectGetMinY(cardContentView.frame)

        height += CGRectGetMinY(featuredImageView.frame)
        height += featuredImageHeightContraint.constant
        height += featuredImageBottomConstraint.constant

        height += titleLabel.sizeThatFits(innerSize).height
        height += titleLabelBottomConstraint.constant

        height += summaryLabel.sizeThatFits(innerSize).height
        height += summaryLabelBottomConstraint.constant

        height += tagLabel.sizeThatFits(innerSize).height
        height += tagLabelBottomConstraint.constant

        height += actionButtonViewHeightConstraint.constant
        height += actionButtonViewBottomConstraint.constant

        height += cardContentBottomConstraint.constant

        return CGSizeMake(size.width, height)
    }

    private func innerWidthForSize(size: CGSize) -> CGFloat {
        var width:CGFloat = 0.0
        var horizontalMargin = CGRectGetMinX(headerView.frame)

        if (UIDevice.isPad()) {
            width = maxIPadWidthConstraint.constant
        } else {
            width = size.width
            horizontalMargin += CGRectGetMinX(cardContentView.frame)
        }
        width -= (horizontalMargin * 2)
        return width
    }


    // MARK - Configuration

    /**
        Applies the default styles to the cell's subviews
    */
    private func applyStyles() {
        backgroundColor = WPStyleGuide.greyLighten30()
        cardBorderView.backgroundColor = WPStyleGuide.readerCardCellBorderColor()

        WPStyleGuide.applyReaderCardSiteLabelStyle(blogNameLabel)
        WPStyleGuide.applyReaderCardBylineLabelStyle(bylineLabel)
        WPStyleGuide.applyReaderCardTitleLabelStyle(titleLabel)
        WPStyleGuide.applyReaderCardSummaryLabelStyle(summaryLabel)

        WPStyleGuide.applyReaderCardActionButtonStyle(actionButtonCenter)
        WPStyleGuide.applyReaderCardActionButtonStyle(actionButtonFlushLeft)
        WPStyleGuide.applyReaderCardActionButtonStyle(actionButtonLeft)
        WPStyleGuide.applyReaderCardActionButtonStyle(actionButtonRight)
    }

    public func configureCell(contentProvider:ReaderPostContentProvider) {
        self.contentProvider = contentProvider

        configureHeader()
        configureCardImage()
        configureTitle()
        configureSummary()
        configureTagAndWordCount()
        configureActionButtons()
    }

    private func configureHeader() {
        if let url = contentProvider?.avatarURLForDisplay() {
            let placeholder = UIImage(named: "post-blavatar-placeholder")
            avatarImageView.setImageWithURL(url, placeholderImage: placeholder)
        }

        if let blogName = contentProvider?.blogNameForDisplay() {
            blogNameLabel.text = blogName
        }

        var byline = contentProvider?.dateForDisplay().shortString()
        if let author = contentProvider?.authorForDisplay() {
            byline = String(format: "%@, %@", byline!, author)
        }
        bylineLabel.text = byline
    }

    private func configureCardImage() {
        // Always clear the previous image so there is no stale or unexpected image 
        // momentarily visible.
        featuredImageView.image = nil
        if let featuredImageURL = contentProvider?.featuredImageURLForDisplay?() {
            featuredImageView.setImageWithURL(featuredImageURL)
            featuredImageHeightContraint.constant = featuredImageHeightConstraintConstant
        } else {
            featuredImageHeightContraint.constant = 0.0
        }
    }

    private func configureTitle() {
        if let title = contentProvider?.titleForDisplay() {
            let attributes = WPStyleGuide.readerCardTitleAttributes()
            titleLabel.attributedText = NSAttributedString(string: title, attributes: attributes)
            titleLabelBottomConstraint.constant = titleLabelBottomConstraintConstant
        } else {
            titleLabel.attributedText = nil
            titleLabelBottomConstraint.constant = 0.0
        }
    }

    private func configureSummary() {
        if let summary = contentProvider?.contentPreviewForDisplay() {
            let attributes = WPStyleGuide.readerCardSummaryAttributes()
            summaryLabel.attributedText = NSAttributedString(string: summary, attributes: attributes)
            summaryLabelBottomConstraint.constant = summaryLabelBottomConstraintConstant
        } else {
            summaryLabel.attributedText = nil
            summaryLabelBottomConstraint.constant = 0.0
        }
        summaryLabel.numberOfLines = 3
        summaryLabel.lineBreakMode = .ByTruncatingTail
    }

    private func configureTagAndWordCount() {
        tagLabel.text = ""
        tagLabelBottomConstraint.constant = 0.0
    }

    private func configureActionButtons() {
        resetActionButtons()
        if contentProvider == nil {
            return
        }

        var buttons = [
            actionButtonLeft,
            actionButtonCenter,
            actionButtonRight]

        // Show Likes
        if contentProvider!.isLikesEnabled() {
            let button = buttons.removeLast() as UIButton
            configureLikeActionButton(button)
        }

        // Show comments
        if contentProvider!.commentsOpen() || contentProvider!.commentCount().integerValue > 0 {
            let button = buttons.removeLast() as UIButton
            configureCommentActionButton(button)

        }

        // Show visit
        if UIDevice.isPad() {
            let button = buttons.removeLast() as UIButton
            configureVisitActionButton(button)
        } else {
            configureVisitActionButton(actionButtonFlushLeft)
        }
    }

    private func resetActionButtons() {
        resetActionButton(actionButtonCenter)
        resetActionButton(actionButtonFlushLeft)
        resetActionButton(actionButtonLeft)
        resetActionButton(actionButtonRight)
    }

    private func resetActionButton(button:UIButton) {
        button.setTitle(nil, forState: .Normal)
        button.setImage(nil, forState: .Normal)
        button.setImage(nil, forState: .Highlighted)
        button.selected = false
        button.hidden = true
    }

    private func configureActionButton(button: UIButton, title: String?, image: UIImage?, highlightedImage: UIImage?) {
        button.setTitle(title, forState: .Normal)
        button.setImage(image, forState: .Normal)
        button.setImage(highlightedImage, forState: .Highlighted)
        button.selected = false
        button.hidden = false
    }

    private func configureLikeActionButton(button: UIButton) {
        button.tag = CardAction.Like.rawValue
        let title = NSLocalizedString("Like", comment: "Text for the 'like' button. Tapping marks a post in the reader as 'liked'.")
        var image = UIImage(named: "reader-postaction-like-blue")
        var highlightImage = UIImage(named: "reader-postaction-like-active")
        configureActionButton(button, title: title, image: image, highlightedImage: highlightImage)
    }

    private func configureCommentActionButton(button: UIButton) {
        button.tag = CardAction.Comment.rawValue
        var title = contentProvider?.commentCount().stringValue
        var image = UIImage(named: "reader-postaction-comment-blue")
        var highlightImage = UIImage(named: "reader-postaction-comment-active")
        configureActionButton(button, title: title, image: image, highlightedImage: highlightImage)
    }

    private func configureVisitActionButton(button: UIButton) {
        button.tag = CardAction.View.rawValue
        let title = NSLocalizedString("View", comment: "")
        var image = UIImage(named: "reader-postaction-like-blue")
        var highlightImage = UIImage(named: "reader-postaction-like-blue")
        configureActionButton(button, title: title, image: image, highlightedImage: highlightImage)
    }

    private func applyHighlightedEffect(highlighted: Bool, animated: Bool) {
        let duration:NSTimeInterval = animated ? 0.25 : 0

        UIView.animateWithDuration(duration,
            delay: 0,
            options: .CurveEaseInOut,
            animations: { () -> Void in
                self.cardBorderView.backgroundColor = highlighted ? WPStyleGuide.readerCardCellHighlightedBorderColor() : WPStyleGuide.readerCardCellBorderColor()
        }, completion: nil)
    }


    // MARK - Actions

    @IBAction func didTapMenuButton(sender: UIButton) {
        delegate?.readerCell(self, menuActionForProvider: contentProvider!, fromView: sender)
    }

    @IBAction func didTapActionButton(sender: UIButton) {
        if contentProvider == nil {
            return
        }

        var tag = CardAction(rawValue: sender.tag)!
        switch tag {
        case .Comment :
            delegate?.readerCell(self, commentActionForProvider: contentProvider!)
        case .Like :
            delegate?.readerCell(self, likeActionForProvider: contentProvider!)
        case .View :
            delegate?.readerCell(self, viewActionForProvider: contentProvider!)
        }
    }

}
