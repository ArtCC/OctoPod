import UIKit

class SystemCommandsViewController: ThemedDynamicUITableViewController, SubpanelViewController  {

    let octoprintClient: OctoPrintClient = { return (UIApplication.shared.delegate as! AppDelegate).octoprintClient }()
    let appConfiguration: AppConfiguration = { return (UIApplication.shared.delegate as! AppDelegate).appConfiguration }()

    var commands: Array<SystemCommand>?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Some bug in XCode Storyboards is not translating text of refresh control so let's do it manually
        self.refreshControl?.attributedTitle = NSAttributedString(string: NSLocalizedString("Pull down to refresh", comment: ""))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Fetch and render system commands
        refreshSystemCommands(done: nil)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return commands == nil ? 0 : commands!.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return NSLocalizedString("System Commands", comment: "http://docs.octoprint.org/en/master/api/system.html")
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "command_cell", for: indexPath)

        // Configure the cell
        if let commandsArray = commands {
            cell.textLabel?.text = commandsArray[indexPath.row].name
        } else {
            cell.textLabel?.text = nil
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Deselect table row to show nice effect and not leave row selected in the UI
        tableView.deselectRow(at: indexPath, animated: true)
        if appConfiguration.appLocked() {
            // Do nothing if app is locked
            return
        }
        if let command = commands?[indexPath.row] {
            // Prompt for confirmation that we want to disconnect from printer
            showConfirm(message: String(format: NSLocalizedString("Confirm command", comment: ""), command.name), yes: { (UIAlertAction) -> Void in
                self.octoprintClient.executeSystemCommand(command: command, callback: { (requested: Bool, error: Error?, response: HTTPURLResponse) in
                    if !requested {
                        // Handle error
                        NSLog("Error executing system command. HTTP status code \(response.statusCode)")
                        self.showAlert(NSLocalizedString("Warning", comment: ""), message: NSLocalizedString("Failed to request to execute command", comment: ""))

                    }
                })
            }, no: { (UIAlertAction) -> Void in
                // Do nothing
            })
        }
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return appConfiguration.appLocked() ? nil : indexPath
    }

    // MARK: - Refresh
    
    @IBAction func refreshControls(_ sender: UIRefreshControl) {
        // Fetch and render custom controls
        refreshSystemCommands(done: {
            DispatchQueue.main.async {
                sender.endRefreshing()
            }
        })
    }
    
    // MARK: - SubpanelViewController

    // Notification that another OctoPrint server has been selected
    func printerSelectedChanged() {
        // Only refresh UI if view controller is being shown
        if let _ = parent {
            // Fetch and render system commands
            refreshSystemCommands(done: nil)
        }
    }
    
    // Notification that OctoPrint state has changed. This may include printer status information
    func currentStateUpdated(event: CurrentStateEvent) {
        // Do nothing
    }
    
    // Returns the position where this VC should appear in SubpanelsViewController's UIPageViewController
    // SubpanelsViewController's will sort subpanels by this number when being displayed
    func position() -> Int {
        return 6
    }

    // MARK: - Private functions
    
    fileprivate func refreshSystemCommands(done: (() -> Void)?) {
        octoprintClient.systemCommands { (commands: Array<SystemCommand>?, error: Error?, response: HTTPURLResponse) in
            self.commands = commands
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            if let _ = error {
                self.showAlert(NSLocalizedString("Warning", comment: ""), message: error!.localizedDescription)
            } else if response.statusCode != 200 {
                self.showAlert(NSLocalizedString("Warning", comment: ""), message: String(format: NSLocalizedString("Failed to get system commands", comment: "Failed to get system commands with HTTP Request error info"), response.statusCode))
            }
            // Execute done block when done
            done?()
        }
    }

    fileprivate func showAlert(_ title: String, message: String) {
        UIUtils.showAlert(presenter: self, title: title, message: message, done: nil)
    }

    fileprivate func showConfirm(message: String, yes: @escaping (UIAlertAction) -> Void, no: @escaping (UIAlertAction) -> Void) {
        UIUtils.showConfirm(presenter: self, message: message, yes: yes, no: no)
    }
}
