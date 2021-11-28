import UIKit

protocol SettingsViewControllerDelegate: class {
    func controller(_ controller: SettingsViewController, didChangeExportAction: ExportAction)
    func controller(_ controller: SettingsViewController, didChangeTimeFormat: TimeFormat)
}

class SettingsViewController: UITableViewController {

    weak var delegate: SettingsViewControllerDelegate?

    private let settings: UserDefaults = .standard

    @IBOutlet private var includeMetadataSwitch: UISwitch!
    @IBOutlet private var imageFormatControl: UISegmentedControl!
    @IBOutlet private var compressionQualityStepper: UIStepper!
    @IBOutlet private var compressionQualityLabel: UILabel!
    @IBOutlet private var compressionQualityStack: UIStackView!
    @IBOutlet private var selectedExportActionLabel: UILabel!
    @IBOutlet private var selectedTimeFormatLabel: UILabel!

    private lazy var compressionFormatter = NumberFormatter.percentFormatter()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateExpandedPreferredContentSize()        
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentContentSize(comparedTo: previousTraitCollection) {
            updateViews(for: traitCollection)
        }
    }
    
    @IBSegueAction private func makeActionSettingsController(_ coder: NSCoder) -> ExportActionSettingsViewController? {
        let controller = ExportActionSettingsViewController(coder: coder)
        controller?.selectedAction = settings.exportAction
        controller?.didSelectAction = { [weak self] action in
            guard let self = self else  { return }
            self.settings.exportAction = action
            self.updateViews()
            self.delegate?.controller(self, didChangeExportAction: action)
        }
        return controller
    }
    
    @IBSegueAction private func makeTimeFormatSettingsController(_ coder: NSCoder) -> TimeFormatSettingsViewController? {
        let controller = TimeFormatSettingsViewController(coder: coder)
        controller?.selectedFormat = settings.timeFormat
        controller?.didSelectFormat = { [weak self] format in
            guard let self = self else  { return }
            self.settings.timeFormat = format
            self.updateViews()
            self.delegate?.controller(self, didChangeTimeFormat: format)
        }
        return controller
    }

    @IBAction private func done() {
        dismiss(animated: true)
    }

    @IBAction private func didUpdateIncludeMetadata(_ sender: UISwitch) {
        settings.includeMetadata = sender.isOn
    }
    
    @IBAction private func didUpdateImageFormat(_ sender: UISegmentedControl) {
        UISelectionFeedbackGenerator().selectionChanged()
        settings.imageFormat = ImageFormat.allCases[sender.selectedSegmentIndex]
    }

    @IBAction private func didChangeCompressionQuality(_ sender: UIStepper) {
        UISelectionFeedbackGenerator().selectionChanged()
        settings.compressionQuality = sender.value/100
        updateViews()
    }

    private func configureViews() {
        compressionQualityLabel.font = UIFont.monospacedDigitSystemFont(forTextStyle: .body)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(done))
        
        configureImageFormatControl()
        updateViews(for: traitCollection)
        updateViews()
    }
        
    private func configureImageFormatControl() {
        let formats = ImageFormat.allCases
        imageFormatControl.removeAllSegments()
        
        formats.enumerated().forEach { (index, format) in
            imageFormatControl.insertSegment(
                withTitle: format.displayString,
                at: index,
                animated: false
            )
            
            imageFormatControl.setEnabled(format.isEncodingSupported, forSegmentAt: index)
        }
    }

    private func updateViews() {
        includeMetadataSwitch.isOn = settings.includeMetadata

        compressionQualityStepper.value = settings.compressionQuality*100
        compressionQualityLabel.text = compressionFormatter.string(from: settings.compressionQuality as NSNumber)
        
        let formatIndex = ImageFormat.allCases.firstIndex(of: settings.imageFormat)
        imageFormatControl.selectedSegmentIndex = formatIndex ?? 0
        
        selectedExportActionLabel.text = settings.exportAction.displayString
        selectedTimeFormatLabel.text = settings.timeFormat.displayString
    }
    
    private func updateViews(for traitCollection: UITraitCollection) {
        compressionQualityStack.axis = traitCollection.hasHugeContentSize ? .vertical : .horizontal
    }
}
