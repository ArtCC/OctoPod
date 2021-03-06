import UIKit
import StoreKit  // Import for rating app

class PrinterSubpanelViewController: ThemedStaticUITableViewController, UIPopoverPresentationControllerDelegate, SubpanelViewController {
    
    private static let RATE_APP = "PANEL_RATE_APP"
    private static let TOOLTIP_PRINT_INFO = "PANEL_TOOLTIP_PRINT_INFO"
    private static let TOOLTIP_TEMP_TOOL = "PANEL_TOOLTIP_TEMP_TOOL"
    private static let TOOLTIP_TEMP_BED = "PANEL_TOOLTIP_TEMP_BED"

    enum buttonsScope {
        case all
        case all_except_connect
    }
    
    @IBOutlet weak var printedTextLabel: UILabel!
    @IBOutlet weak var printTimeTextLabel: UILabel!
    @IBOutlet weak var printTimeLeftTextLabel: UILabel!
    @IBOutlet weak var printerStatusTextLabel: UILabel!
    @IBOutlet weak var tool0TextLabel: UILabel!
    @IBOutlet weak var bedTextLabel: UILabel!
    @IBOutlet weak var tool1TextLabel: UILabel!
    
    @IBOutlet weak var printerStatusLabel: UILabel!
    
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var printTimeLabel: UILabel!
    @IBOutlet weak var printTimeLeftLabel: UILabel!
    @IBOutlet weak var printJobButton: UIButton!
    
    @IBOutlet weak var tool0SetTempButton: UIButton!
    @IBOutlet weak var tool0ActualLabel: UILabel!
    @IBOutlet weak var tool0TargetLabel: UILabel!
    @IBOutlet weak var tool0SplitLabel: UILabel!
    
    @IBOutlet weak var tool1Row: UITableViewCell!
    @IBOutlet weak var tool1SetTempButton: UIButton!
    @IBOutlet weak var tool1ActualLabel: UILabel!
    @IBOutlet weak var tool1TargetLabel: UILabel!
    @IBOutlet weak var tool1SplitLabel: UILabel!
    
    @IBOutlet weak var bedSetTempButton: UIButton!
    @IBOutlet weak var bedActualLabel: UILabel!
    @IBOutlet weak var bedTargetLabel: UILabel!
    @IBOutlet weak var bedSplitLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Round the corners of the progres bar
        progressView.layer.cornerRadius = 8
        progressView.clipsToBounds = true
        progressView.layer.sublayers![1].cornerRadius = 8
        progressView.subviews[1].clipsToBounds = true
        
        clearValues()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        themeLabels()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view operations

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }

     // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "set_target_temp_bed" {
            if let controller = segue.destination as? SetTargetTempViewController {
                controller.targetTempScope = SetTargetTempViewController.TargetScope.bed
                controller.popoverPresentationController!.delegate = self
                // Make the popover appear at the middle of the button
                segue.destination.popoverPresentationController!.sourceRect = CGRect(x: bedSetTempButton.frame.size.width/2, y: 0 , width: 0, height: 0)
            }
        } else if segue.identifier == "bed_tooltip" {
            segue.destination.popoverPresentationController!.delegate = self
            // Make the popover appear at the middle of the button
            segue.destination.popoverPresentationController!.sourceRect = CGRect(x: bedSetTempButton.frame.size.width/2, y: 0 , width: 0, height: 0)
        } else if segue.identifier == "set_target_temp_tool0" {
            if let controller = segue.destination as? SetTargetTempViewController {
                controller.targetTempScope = SetTargetTempViewController.TargetScope.tool0
                controller.popoverPresentationController!.delegate = self
                // Make the popover appear at the middle of the button
                segue.destination.popoverPresentationController!.sourceRect = CGRect(x: tool0SetTempButton.frame.size.width/2, y: 0 , width: 0, height: 0)
            }
        } else if segue.identifier == "tool0_tooltip" {
            segue.destination.popoverPresentationController!.delegate = self
            // Make the popover appear at the middle of the button
            segue.destination.popoverPresentationController!.sourceRect = CGRect(x: tool0SetTempButton.frame.size.width/2, y: 0 , width: 0, height: 0)
        } else if segue.identifier == "set_target_temp_tool1" {
            if let controller = segue.destination as? SetTargetTempViewController {
                controller.targetTempScope = SetTargetTempViewController.TargetScope.tool1
                controller.popoverPresentationController!.delegate = self
                // Make the popover appear at the middle of the button
                segue.destination.popoverPresentationController!.sourceRect = CGRect(x: tool1SetTempButton.frame.size.width/2, y: 0 , width: 0, height: 0)
            }
        } else if segue.identifier == "print_job_info" {
            segue.destination.popoverPresentationController!.delegate = self
            // Make the popover appear at the middle of the button
            let devicePortrait = UIApplication.shared.statusBarOrientation.isPortrait
            let y = devicePortrait ? 0 : printJobButton.frame.size.height
            segue.destination.popoverPresentationController!.sourceRect = CGRect(x: printJobButton.frame.size.width/2, y: y , width: 0, height: 0)
        } else if segue.identifier == "print_job_tooltip" {
            segue.destination.popoverPresentationController!.delegate = self
            // Make the popover appear at the middle of the button
            let devicePortrait = UIApplication.shared.statusBarOrientation.isPortrait
            let y = devicePortrait ? 0 : printJobButton.frame.size.height
            segue.destination.popoverPresentationController!.sourceRect = CGRect(x: printJobButton.frame.size.width/2, y: y , width: 0, height: 0)
        }
    }
    
    // MARK: - SubpanelViewController

    func printerSelectedChanged() {
        clearValues()
    }
    
    // Notification that OctoPrint state has changed. This may include printer status information
    func currentStateUpdated(event: CurrentStateEvent) {
        // Check if we should prompt user to rate app
        checkRateApp(event: event)
        
        DispatchQueue.main.async {
            if let state = event.state {
                self.printerStatusLabel.text = state
            }

            if let progress = event.progressCompletion {
                let progressText = String(format: "%.1f", progress)
                self.progressLabel.text = "\(progressText)%"
                self.progressView.setProgress(Float(progressText)! / 100, animated: true) // Convert Float from String to prevent weird behaviors
                self.printJobButton.isEnabled = progress > 0
                
                self.presentToolTip(tooltipKey: PrinterSubpanelViewController.TOOLTIP_PRINT_INFO, segueIdentifier: "print_job_tooltip", button: self.printJobButton)
            }
            
            if let seconds = event.progressPrintTime {
                self.printTimeLabel.text = self.secondsToPrintTime(seconds: seconds)
            }

            if let seconds = event.progressPrintTimeLeft {
                self.printTimeLeftLabel.text = self.secondsToTimeLeft(seconds: seconds)
            } else if event.progressPrintTime != nil {
                self.printTimeLeftLabel.text = NSLocalizedString("Still stabilizing", comment: "Print time is being calculated")
            }

            if let tool0Actual = event.tool0TempActual {
                self.tool0ActualLabel.text = "\(String(format: "%.1f", tool0Actual)) C"
                self.tool0SplitLabel.isHidden = false
            }
            if let tool0Target = event.tool0TempTarget {
                self.tool0TargetLabel.text = "\(String(format: "%.0f", tool0Target)) C"
                self.tool0SplitLabel.isHidden = false
            }

            if let tool1Actual = event.tool1TempActual {
                self.tool1ActualLabel.text = "\(String(format: "%.1f", tool1Actual)) C"
                self.tool1Row.isHidden = false
            }
            if let tool1Target = event.tool1TempTarget {
                self.tool1TargetLabel.text = "\(String(format: "%.0f", tool1Target)) C"
                self.tool1Row.isHidden = false
            }
            
            if let bedActual = event.bedTempActual {
                self.bedActualLabel.text = "\(String(format: "%.1f", bedActual)) C"
                self.bedSplitLabel.isHidden = false
            }
            if let bedTarget = event.bedTempTarget {
                self.bedTargetLabel.text = "\(String(format: "%.0f", bedTarget)) C"
                self.bedSplitLabel.isHidden = false
            }
            
            if let disconnected = event.closedOrError {
                self.bedSetTempButton.isEnabled = !disconnected
                self.tool0SetTempButton.isEnabled = !disconnected
                self.tool1SetTempButton.isEnabled = !disconnected

                self.presentToolTip(tooltipKey: PrinterSubpanelViewController.TOOLTIP_TEMP_BED, segueIdentifier: "bed_tooltip", button: self.bedSetTempButton)
                self.presentToolTip(tooltipKey: PrinterSubpanelViewController.TOOLTIP_TEMP_TOOL, segueIdentifier: "tool0_tooltip", button: self.tool0SetTempButton)
            }
        }
    }
    
    // Returns the position where this VC should appear in SubpanelsViewController's UIPageViewController
    // SubpanelsViewController's will sort subpanels by this number when being displayed
    func position() -> Int {
        return 0
    }

    // MARK: - UIPopoverPresentationControllerDelegate
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    // We need to add this so it works on iPhone plus in landscape mode
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }

    // MARK: - Rate app - Private functions

    // Ask user to rate app. We will ask a maximum of 3 times and only after a job is 100% done.
    // We will ask when job #3, #10 or #30 are done. Only for iOS 10.3 or newer installations
    fileprivate func checkRateApp(event: CurrentStateEvent) {
        let firstAsk = 2
        let secondAsk = 9
        let thirdAsk = 29
        if let progress = event.progressCompletion {
            // Ask users to rate the app only when print job was completed (and after X number of jobs were done)
            if progress == 100 && progressView.progress < 1 {
                let defaults = UserDefaults.standard
                let counter = defaults.integer(forKey: PrinterSubpanelViewController.RATE_APP)
                if counter > thirdAsk {
                    // Stop asking user to rate app
                    return
                }
                if counter == firstAsk || counter == secondAsk || counter == thirdAsk {
                    // Prompt user to rate the app
                    // Only prompt to rate the app if device has iOS 10.3 or later
                    // Not many people use older than 10.3 based on App Store Connect so only implementing this
                    if #available(iOS 10.3, *) {
                        // Wait 2 seconds before prompting so UI can refresh progress
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            SKStoreReviewController.requestReview()
                        }
                    }
                }
                // Increment count
                defaults.set(counter + 1, forKey: PrinterSubpanelViewController.RATE_APP)
            }
        }
    }
    
    // MARK: - Private functions
    
    // Converts number of seconds into a string that represents time (e.g. 23h 10m)
    func secondsToPrintTime(seconds: Int) -> String {
        let duration = TimeInterval(seconds)
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .brief
        formatter.allowedUnits = [ .day, .hour, .minute, .second ]
        formatter.zeroFormattingBehavior = [ .default ]
        return formatter.string(from: duration)!
    }
    
    func secondsToTimeLeft(seconds: Int) -> String {
        if seconds == 0 {
            return ""
        } else if seconds < 0 {
            // Should never happen but an OctoPrint plugin is returning negative values
            // so return 'Unknown' when this happens
            return NSLocalizedString("Unknown", comment: "ETA is Unknown")
        }
        let duration = TimeInterval(seconds)
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .brief
        formatter.includesApproximationPhrase = true
        formatter.allowedUnits = [ .day, .hour, .minute ]
        return formatter.string(from: duration)!
    }
    
    fileprivate func presentToolTip(tooltipKey: String, segueIdentifier: String, button: UIButton) {
        let tooltipShown = UserDefaults.standard.bool(forKey: tooltipKey)
        if button.isEnabled && !tooltipShown && self.presentedViewController == nil {
            UserDefaults.standard.set(true, forKey: tooltipKey)
            self.performSegue(withIdentifier: segueIdentifier, sender: self)
        }
    }
    
    fileprivate func clearValues() {
        DispatchQueue.main.async {
            self.printerStatusLabel.text = NSLocalizedString("Offline", comment: "Printer is Offline")

            self.progressView.setProgress(0, animated: false)
            self.progressLabel.text = "0%"
            self.printTimeLabel.text = ""
            self.printTimeLeftLabel.text = ""
            self.printJobButton.isEnabled = false
            
            self.tool0ActualLabel.text = ""
            self.tool0TargetLabel.text = ""
            self.tool0SplitLabel.isHidden = true
            // Hide second extruder unless printe reports that it has one
            self.tool1Row.isHidden = true
            
            self.bedActualLabel.text = "            " // Use empty spaces to position Bed label in a good place
            self.bedTargetLabel.text = "        " // Use empty spaces to position Bed label in a good place
            self.bedSplitLabel.isHidden = true
            
            // Disable these buttons
            self.bedSetTempButton.isEnabled = false
            self.tool0SetTempButton.isEnabled = false
            self.tool1SetTempButton.isEnabled = false
        }
    }
    
    fileprivate func themeLabels() {
        let theme = Theme.currentTheme()
        let textLabelColor = theme.labelColor()
        let textColor = theme.textColor()
        
        printedTextLabel.textColor = textLabelColor
        printTimeTextLabel.textColor = textLabelColor
        printTimeLeftTextLabel.textColor = textLabelColor
        printerStatusTextLabel.textColor = textLabelColor
        tool0TextLabel.textColor = textLabelColor
        bedTextLabel.textColor = textLabelColor
        tool1TextLabel.textColor = textLabelColor
        tool0SplitLabel.textColor = textLabelColor
        tool1SplitLabel.textColor = textLabelColor
        bedSplitLabel.textColor = textLabelColor

        printerStatusLabel.textColor = textColor
        progressLabel.textColor = textColor
        printTimeLabel.textColor = textColor
        printTimeLeftLabel.textColor = textColor
        tool0ActualLabel.textColor = textColor
        tool0TargetLabel.textColor = textColor
        tool1ActualLabel.textColor = textColor
        tool1TargetLabel.textColor = textColor
        bedActualLabel.textColor = textColor
        bedTargetLabel.textColor = textColor
    }
}
