//
//  TransactionConfirmationHeaderView.swift
//  AlphaWallet
//
//  Created by Vladyslav Shepitko on 10.07.2020.
//

import UIKit

protocol TransactionConfirmationHeaderViewDelegate: AnyObject {
    func headerView(_ header: TransactionConfirmationHeaderView, shouldHideChildren section: Int, index: Int) -> Bool
    func headerView(_ header: TransactionConfirmationHeaderView, shouldShowChildren section: Int, index: Int) -> Bool
    func headerView(_ header: TransactionConfirmationHeaderView, openStateChanged section: Int)
    func headerView(_ header: TransactionConfirmationHeaderView, tappedSection section: Int)
}

class TransactionConfirmationHeaderView: UIView {

    struct Configuration {
        var isOpened: Bool = false
        let section: Int
        var shouldHideChevron: Bool = true
    }

    private var isTapActionEnabled = false

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    private let titleIconImageView: UIImageView = {
        return UIImageView()
    }()

    private let detailsLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0

        return label
    }()

    private lazy var chevronView: UIView = {
        let view = UIView()
        view.addSubview(chevronImageView)

        return view
    }()

    private let chevronImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = R.color.black()
        imageView.contentMode = .scaleAspectFit

        return imageView
    }()

    lazy var trailingStackView: UIStackView = {
        return [].asStackView(axis: .horizontal)
    }()

    lazy var childrenStackView: UIStackView = {
        return [].asStackView(axis: .vertical)
    }()

    private var isSelectedObservation: NSKeyValueObservation!
    private var viewModel: TransactionConfirmationHeaderViewModel

    weak var delegate: TransactionConfirmationHeaderViewDelegate?

    init(viewModel: TransactionConfirmationHeaderViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)

        translatesAutoresizingMaskIntoConstraints = false

        let separatorLine = UIView()
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        separatorLine.backgroundColor = R.color.mercury()

        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        let titleRow = [titleIconImageView, titleLabel].asStackView(axis: .horizontal, spacing: 6)

        let col0 = nameLabel
        let col1 = [
            titleRow,
            detailsLabel
        ].asStackView(axis: .vertical, alignment: .leading)
        col1.translatesAutoresizingMaskIntoConstraints = false

        let contents = UIView()
        contents.translatesAutoresizingMaskIntoConstraints = false
        contents.addSubview(col0)
        contents.addSubview(col1)

        let row0 = [.spacerWidth(ScreenChecker().isNarrowScreen ? 8 : 16), contents, trailingStackView, chevronView, .spacerWidth(ScreenChecker().isNarrowScreen ? 8 : 16)].asStackView(axis: .horizontal, alignment: .top)

        let headerViews = [
            separatorLine,
            .spacer(height: ScreenChecker().isNarrowScreen ? 10 : 20),
            row0,
            .spacer(height: ScreenChecker().isNarrowScreen ? 10 : 20)
        ]

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
        isUserInteractionEnabled = true
        addGestureRecognizer(tap)

        let stackView = (headerViews + [childrenStackView]).asStackView(axis: .vertical)

        stackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stackView)

        NSLayoutConstraint.activate([
            trailingStackView.heightAnchor.constraint(equalTo: row0.heightAnchor),
            nameLabel.topAnchor.constraint(equalTo: contents.topAnchor, constant: 5),
            nameLabel.leadingAnchor.constraint(equalTo: contents.leadingAnchor),
            nameLabel.widthAnchor.constraint(equalToConstant: 80),

            titleLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),

            titleIconImageView.widthAnchor.constraint(equalToConstant: 24),
            titleIconImageView.widthAnchor.constraint(equalTo: titleIconImageView.heightAnchor),

            col1.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: ScreenChecker().isNarrowScreen ? 8 : 16),
            col1.trailingAnchor.constraint(equalTo: contents.trailingAnchor),
            col1.topAnchor.constraint(lessThanOrEqualTo: nameLabel.topAnchor),
            col1.bottomAnchor.constraint(equalTo: contents.bottomAnchor),

            separatorLine.heightAnchor.constraint(equalToConstant: 1),

            chevronImageView.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            chevronImageView.bottomAnchor.constraint(equalTo: chevronView.bottomAnchor),
            chevronImageView.trailingAnchor.constraint(equalTo: chevronView.trailingAnchor),
            chevronImageView.leadingAnchor.constraint(equalTo: chevronView.leadingAnchor),

            stackView.anchorsConstraint(to: self)
        ])

        configure(viewModel: viewModel)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    private func configure(viewModel: TransactionConfirmationHeaderViewModel) {
        backgroundColor = viewModel.backgroundColor

        chevronView.isHidden = viewModel.configuration.shouldHideChevron

        chevronImageView.image = viewModel.chevronImage

        titleIconImageView.isHidden = viewModel.isTitleIconHidden
        titleIconImageView.image = viewModel.titleIcon

        titleLabel.alpha = viewModel.titleAlpha
        titleLabel.attributedText = viewModel.titleAttributedString
        titleLabel.isHidden = titleLabel.attributedText == nil

        nameLabel.attributedText = viewModel.headerNameAttributedString
        nameLabel.isHidden = nameLabel.attributedText == nil

        detailsLabel.attributedText = viewModel.detailsAttributedString
        detailsLabel.isHidden = detailsLabel.attributedText == nil
    }

    @objc private func didTap(_ sender: UITapGestureRecognizer) {
        if isTapActionEnabled {
            delegate?.headerView(self, tappedSection: viewModel.configuration.section)
        } else {
            viewModel.configuration.isOpened.toggle()

            chevronImageView.image = viewModel.chevronImage
            titleLabel.alpha = viewModel.titleAlpha

            delegate?.headerView(self, openStateChanged: viewModel.configuration.section)
        }
    }

    func expand() {
        guard let delegate = delegate else { return }

        for (index, view) in childrenStackView.arrangedSubviews.enumerated() {
            if delegate.headerView(self, shouldShowChildren: viewModel.configuration.section, index: index) {
                view.isHidden = false
            }
        }
    }

    func collapse() {
        guard let delegate = delegate else { return }

        for (index, view) in childrenStackView.arrangedSubviews.enumerated() {
            if delegate.headerView(self, shouldHideChildren: viewModel.configuration.section, index: index) {
                view.isHidden = true
            }
        }
    }
}

extension TransactionConfirmationHeaderView {
    func enableTapAction(title: String) {
        isTapActionEnabled = true

        let label = UILabel()
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .right

        label.attributedText = NSAttributedString(string: title, attributes: [
            .font: Fonts.bold(size: 17) as Any,
            .foregroundColor: R.color.azure() as Any,
            .paragraphStyle: paragraph
        ])
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .horizontal)

        let wrapper = UIView()
        wrapper.addSubview(label)

        trailingStackView.addArrangedSubview(wrapper)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            label.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            label.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
            label.heightAnchor.constraint(greaterThanOrEqualToConstant: 20),
        ])
    }
}
