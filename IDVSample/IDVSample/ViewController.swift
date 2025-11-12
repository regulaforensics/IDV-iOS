//
//  ViewController.swift
//  IDVSample
//
//  Created by Serge Rylko on 19.03.25.
//

import UIKit
import IDVSDK

class ViewController: UIViewController {

  private enum LoadingStep {
    case configuring
    case loadingWorkflows
    case preparingWorkflows

    var loadingText: String? {
      switch self {
      case .configuring:
        return "Configuring SDK …"
      case .loadingWorkflows:
        return "Loading workflows …"
      case .preparingWorkflows:
        return "Preparing workflow …"
      }
    }
  }
  private var configured: Bool = false {
    didSet {
      updateConfigureButtonsAppearance()
    }
  }

  @IBOutlet weak var loadingView: UIView!

  @IBOutlet private weak var loadingTitleLabel: UILabel!
  @IBOutlet private weak var loadingActivity: UIActivityIndicatorView!

  @IBOutlet weak var configureByURLButton: UIButton!
  @IBOutlet weak var configureByApiKeyButton: UIButton!
  @IBOutlet weak var configureByTokenButton: UIButton!
  @IBOutlet weak var configureByCredentialsButton: UIButton!

  @IBOutlet weak var workflowsTitleLabel: UILabel!
  @IBOutlet weak var workflowsTableView: UITableView!

  @IBOutlet weak var restoreModeTitleLabel: UILabel!
  @IBOutlet weak var restoreModeSwitch: UISwitch!

  @IBOutlet private weak var startWorkflowButton: UIButton!


  private lazy var credentials: Credentials = {
    .init(userName: "" , //TO INSERT
          password: "", //TO INSERT
          host: "") // TO INSERT
  }()

  private lazy var apiKeyConfiguration: ApiKeyConfiguration = {
    .init(apiKey: "", // TO INSERT
          host: "") //TO INSERT
  }()

  private lazy var tokenUrl: String = "" //TO INSERT

  private var latestPreparedWorkflowId: String? {
    didSet {
      updateStartButtonAppearance()
    }
  }

  private var workflows: [Workflow] = [] {
    didSet {
      updateWorkflowsTitleAppearance()
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    initializeIDV()
    workflowsTableView.dataSource = self
    workflowsTableView.delegate = self
    workflowsTableView.register(WorkflowCell.self, forCellReuseIdentifier: "WorkflowCell")
  }

  // MARK: - IDV Calls
  private func initializeIDV() {
    showLoading(step: .configuring)

    IDV.shared.initialize(config: .init()) { [weak self] result in
      self?.hideLoading()

      switch result {
      case .success:
        print("Init completed")
      case .failure(let error):
        self?.showAlert(title: "Init failed", message: error.fullChain)
      }
    }
  }

  // MARK: - IDV Configuration

  private func configureByCredentials() {
    guard credentials.isValid() else {
      self.showAlert(title: "Credentials configuration failed", message: "Credentials are empty")
      return
    }
    let config = CredentialsConnectionConfig(userName: credentials.userName,
                                             password: credentials.password,
                                             baseURL: credentials.host)
    showLoading(step: .configuring)

    IDV.shared.configure(with: config) { [weak self] result in
      self?.configured = true
      self?.hideLoading()

      switch result {
      case .success:
        self?.getWorkflows()
      case .failure(let error):
        self?.showAlert(title: "Credentials configuration failed", message: error.fullChain)
      }
    }
  }

  private func configureByApiKey() {
    guard apiKeyConfiguration.isValid() else {
      self.showAlert(title: "API Key configuration failed", message: "Invalid api key configuration")
      return
    }
    let config = ApiKeyConnectionConfig(apiKey: apiKeyConfiguration.apiKey,
                                        baseURL: apiKeyConfiguration.host)
    showLoading(step: .configuring)

    IDV.shared.configure(with: config) { [weak self] result in
      self?.configured = true
      self?.hideLoading()

      switch result {
      case .success:
        self?.getWorkflows()
      case .failure(let error):
        self?.showAlert(title: "API Key configuration failed", message: error.fullChain)
      }
    }
  }

  private func configure(with tokenURL: String) {
    guard !tokenURL.isEmpty else {
      self.showAlert(title: "Token configuration failed", message: "Token url is empty")
      return
    }

    showLoading(step: .configuring)

    IDV.shared.configure(with: TokenConnectionConfig(url: tokenURL)) { [weak self] configureResults in
      self?.hideLoading()

      switch configureResults {
      case .success(let workflowIds):

        if workflowIds.isEmpty {
          self?.showAlert(title: "Token configuration failed", message: "Workflow Ids is empty")
        } else {
          self?.getWorkflows(filter: workflowIds)
        }
      case .failure(let error):
        self?.showAlert(title: "Token configuration failed", message: error.fullChain)
      }
    }
  }

  // MARK: - IDV Get Workflows

  private func getWorkflows(filter workflowIds: [String]? = nil) {
    self.showLoading(step: .loadingWorkflows)
    IDV.shared.getWorkflows(completion: { [weak self] result in
      self?.hideLoading()
      switch result {
      case .success(let workflows):
        if let workflowIds {
          self?.updateWorkflows(with: workflows.filter({ workflowIds.contains($0.id) }))
        } else {
          self?.updateWorkflows(with: workflows)
        }
        print("Succesfully get workflows")
      case .failure(let error):
        self?.showAlert(title: "Get workflow failed", message: error.fullChain)
      }
    })
  }

  // MARK: - IDV Prepare Workflow

  private func prepareWorkflow(workflowId: String) {
    let workflowConfig = PrepareWorkflowConfig(workflowId: workflowId)
    self.showLoading(step: .preparingWorkflows)
    IDV.shared.prepareWorkflow(by: workflowConfig) { [weak self] prepareResults in
      self?.hideLoading()

      switch prepareResults {
      case .success:
        self?.latestPreparedWorkflowId = workflowId
        self?.workflowsTableView.reloadData()
      case .failure(let error):
        self?.showAlert(title: "Prepare workflow failed", message: error.fullChain)
      }
    }
  }

  // MARK: - IDV Start Workflow

  private func startWorkflow(workflowId: String) {
    let config = StartWorkflowConfig.default()
    config.metadata = ["test": true]
    config.locale = "en"

    IDV.shared.startWorkflow(presenter: self, config: config) { [weak self] result in
      switch result {
      case .success(let results):
        print("Completed", results.sessionId)
      case .failure(let error):
        self?.showAlert(title: "Start workflow failed", message: error.fullChain)
      }
    }
  }

  //MARK: - Actions

  @IBAction private func didPressConfigureByToken(_ sender: Any) {
    reset()
    let scanController = ScanViewController()
    scanController.delegate = self
    navigationController?.pushViewController(scanController, animated: true)
  }

  @IBAction private func didPressConfigureByCredentials(_ sender: Any) {
    reset()
    configureByCredentials()
  }

  @IBAction private func didPressConfigureByApikey(_ sender: Any) {
    reset()
    configureByApiKey()
  }

  @IBAction func didPressConfigureByUrl(_ sender: Any) {
    reset()
    configure(with: tokenUrl)
  }

  @IBAction func didPressRestoreMode(_ sender: Any) {
    IDV.shared.sessionRestoreMode = restoreModeSwitch.isOn ? .enabled : .disabled
  }

  @IBAction private func didPressStartWorkflow(_ sender: Any) {
    guard let latestPreparedWorkflowId else { return }
    startWorkflow(workflowId: latestPreparedWorkflowId)
  }

  //MARK: Supplementary

  private func reset() {
    configured = false
    workflows = []
    latestPreparedWorkflowId = nil
    workflowsTableView.reloadData()
    updateConfigureButtonsAppearance()
  }
  private func showLoading(step: LoadingStep) {
    loadingView.alpha = 0.9
    loadingTitleLabel.text = step.loadingText
    loadingTitleLabel.isHidden = false
    loadingActivity.startAnimating()
    view.bringSubviewToFront(loadingView)
  }

  private func hideLoading() {
    loadingTitleLabel.isHidden = true
    loadingTitleLabel.text = nil
    loadingActivity.stopAnimating()
    view.sendSubviewToBack(loadingView)
  }

  private func updateConfigureButtonsAppearance() {
    configureByCredentialsButton.isEnabled = !configured
    configureByApiKeyButton.isEnabled = !configured
  }

  private func updateWorkflowsTitleAppearance() {
    workflowsTitleLabel.isHidden = workflows.isEmpty
  }

  private func updateStartButtonAppearance() {
    startWorkflowButton.isEnabled = latestPreparedWorkflowId != nil
  }

  private func updateWorkflows(with workflows: [Workflow]) {
    self.workflows = workflows
    workflowsTableView.reloadData()

    if workflows.count == 1, let workflowId =  workflows.first?.id {
      prepareWorkflow(workflowId: workflowId)
    }
  }
}

// MARK: - ScanViewControllerDelegate

extension ViewController: ScanViewControllerDelegate {

  func didDetectQRCode(controller: ScanViewController, code: String) {
    configure(with: code)
  }

  func didReceiveScanError(controller: ScanViewController, error: ScanError) {
    showAlert(message: error.localizedDescription)
  }
}

// MARK: - UITableViewDelegate

extension ViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let workflowId = workflows[indexPath.row].id
    if latestPreparedWorkflowId != workflowId {
      latestPreparedWorkflowId = nil
      prepareWorkflow(workflowId: workflowId)
    }
  }
}

// MARK: - UITableViewDataSource

extension ViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    workflows.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: "WorkflowCell", for: indexPath) as? WorkflowCell else { return UITableViewCell() }
    let wf = workflows[indexPath.row]
    let isPrepared = (latestPreparedWorkflowId == wf.id)
    cell.configure(title: wf.name, prepared: isPrepared)
    return cell
  }
}

extension ViewController {

  func showAlert(title: String = "Error", message: String) {
    let presentBlock = {
      let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "Copy", style: .default, handler: { _ in
        UIPasteboard.general.string = message
      }))
      alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
      self.present(alert, animated: true, completion: nil)
    }
    if Thread.isMainThread {
      presentBlock()
    } else {
      DispatchQueue.main.async { presentBlock() }
    }
  }
}

