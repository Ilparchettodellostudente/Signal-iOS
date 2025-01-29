//
// Copyright 2025 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

import UIKit
import SignalServiceKit
import SignalUI

class RegistrationSpeechToTextView: UIView {
    
    enum SpeechToTextOption: String, CaseIterable {
        case native = "Native"
        case base = "Base"
        case medium = "Medium"
        case high = "High"
        case custom = "Custom"
        
        var description: String {
            switch self {
            case .native:
                return "Integrated into the operating system"
            case .base:
                return "Light and fast"
            case .medium:
                return "Balanced between accuracy and performance"
            case .high:
                return "Greater accuracy"
            case .custom:
                return "Manual choice"
            }
        }
        
        var downloadSize: String {
            switch self {
            case .native:
                return "No download required"
            case .base:
                return "~50MB"
            case .medium:
                return "~150MB"
            case .high:
                return "~300MB"
            case .custom:
                return "Size varies"
            }
        }
    }
    
    private var selectedOption: SpeechToTextOption = .native {
        didSet {
            updateDownloadLabel()
        }
    }
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel.titleLabelForRegistration(text: OWSLocalizedString(
            "REGISTRATION_SPEECH_TO_TEXT_TITLE",
            comment: "Title for the speech to text registration screen"
        ))
        label.accessibilityIdentifier = "RegistrationSpeechToText.titleLabel"
        return label
    }()
    
    private lazy var explanationLabel: UILabel = {
        let label = UILabel.explanationLabelForRegistration(text: OWSLocalizedString(
            "REGISTRATION_SPEECH_TO_TEXT_DESCRIPTION",
            comment: "Description for the speech to text registration screen"
        ))
        label.accessibilityIdentifier = "RegistrationSpeechToText.explanationLabel"
        return label
    }()
    
    private lazy var downloadLabel: UILabel = {
        let label = UILabel()
        label.font = .dynamicTypeSubheadlineClamped
        label.textColor = Theme.secondaryTextAndIconColor
        label.textAlignment = .center
        label.numberOfLines = 0
        label.accessibilityIdentifier = "RegistrationSpeechToText.downloadLabel"
        return label
    }()
    
    private lazy var optionsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.alignment = .fill
        
        SpeechToTextOption.allCases.forEach { option in
            stackView.addArrangedSubview(createOptionView(for: option))
        }
        
        return stackView
    }()
    
    private lazy var continueButton: OWSFlatButton = {
        let button = OWSFlatButton.primaryButtonForRegistration(
            title: OWSLocalizedString(
                "REGISTRATION_SPEECH_TO_TEXT_CONTINUE",
                comment: "Button to continue with speech to text registration"
            ),
            target: self,
            selector: #selector(didTapContinue)
        )
        button.accessibilityIdentifier = "RegistrationSpeechToText.continueButton"
        return button
    }()
    
    private lazy var skipButton: OWSFlatButton = {
        let button = OWSFlatButton.linkButtonForRegistration(
            title: OWSLocalizedString(
                "REGISTRATION_SPEECH_TO_TEXT_SKIP",
                comment: "Button to skip speech to text registration"
            ),
            target: self,
            selector: #selector(didTapSkip)
        )
        button.accessibilityIdentifier = "RegistrationSpeechToText.skipButton"
        return button
    }()
    
    private func createOptionView(for option: SpeechToTextOption) -> UIView {
        let container = UIView()
        container.backgroundColor = Theme.secondaryBackgroundColor
        container.layer.cornerRadius = 10
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        
        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 4
        
        let titleLabel = UILabel()
        titleLabel.text = option.rawValue
        titleLabel.font = .dynamicTypeBodyClamped.semibold()
        titleLabel.textColor = Theme.primaryTextColor
        
        let descriptionLabel = UILabel()
        descriptionLabel.text = option.description
        descriptionLabel.font = .dynamicTypeSubheadlineClamped
        descriptionLabel.textColor = Theme.secondaryTextAndIconColor
        descriptionLabel.numberOfLines = 0
        
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(descriptionLabel)
        
        let radioButton = UIImageView()
        radioButton.contentMode = .scaleAspectFit
        radioButton.autoSetDimensions(to: CGSize(square: 24))
        radioButton.tag = 100 // Tag per identificare il radio button
        updateRadioButton(radioButton, isSelected: selectedOption == option)
        
        stackView.addArrangedSubview(textStack)
        stackView.addArrangedSubview(radioButton)
        
        container.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges()
        
        // Aggiungi gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(optionTapped(_:)))
        container.addGestureRecognizer(tapGesture)
        container.tag = SpeechToTextOption.allCases.firstIndex(of: option) ?? 0
        
        return container
    }
    
    private func updateRadioButton(_ imageView: UIImageView, isSelected: Bool) {
        imageView.image = isSelected ?
            Theme.iconImage(.checkCircle).withRenderingMode(.alwaysTemplate) :
            Theme.iconImage(.circle).withRenderingMode(.alwaysTemplate)
        imageView.tintColor = isSelected ? .ows_accentBlue : Theme.secondaryTextAndIconColor
    }
    
    weak var delegate: RegistrationSpeechToTextViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = Theme.backgroundColor
        
        let stackView = UIStackView(arrangedSubviews: [
            titleLabel,
            explanationLabel,
            optionsStackView,
            downloadLabel,
            UIView.vStretchingSpacer(),
            continueButton,
            skipButton
        ])
        
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 12
        stackView.setCustomSpacing(24, after: explanationLabel)
        stackView.setCustomSpacing(16, after: optionsStackView)
        stackView.setCustomSpacing(24, after: downloadLabel)
        stackView.setCustomSpacing(8, after: continueButton)
        
        addSubview(stackView)
        stackView.autoPinEdgesToSuperviewMargins()
        
        updateDownloadLabel()
    }
    
    private func updateDownloadLabel() {
        switch selectedOption {
        case .native:
            downloadLabel.text = "No download required"
        default:
            let baseText = "The selected model (\(selectedOption.downloadSize)) will be downloaded in the background"
            let text = selectedOption == .custom ?
                      "\(baseText)\nYou can change the model settings later" :
                      baseText
            downloadLabel.text = text
        }
    }
    
    @objc
    private func optionTapped(_ gesture: UITapGestureRecognizer) {
        guard let index = gesture.view?.tag,
              let option = SpeechToTextOption.allCases[safe: index] else { return }
        
        selectedOption = option
        
        // Aggiorna tutti i radio button
        optionsStackView.arrangedSubviews.forEach { container in
            if let stackView = container.subviews.first as? UIStackView,
               let radioButton = stackView.arrangedSubviews.last as? UIImageView {
                updateRadioButton(radioButton, isSelected: container.tag == index)
            }
        }
    }
    
    @objc
    private func didTapContinue() {
        delegate?.registrationSpeechToTextViewDidTapContinue(withOption: selectedOption)
    }
    
    @objc
    private func didTapSkip() {
        delegate?.registrationSpeechToTextViewDidTapSkip()
    }
}

protocol RegistrationSpeechToTextViewDelegate: AnyObject {
    func registrationSpeechToTextViewDidTapContinue(withOption option: RegistrationSpeechToTextView.SpeechToTextOption)
    func registrationSpeechToTextViewDidTapSkip()
}
