//
//  WorkflowTitleCell.swift
//  IDVSample
//
//  Created by Антон Потапчик on 11.11.25.
//

import UIKit

final class WorkflowCell: UITableViewCell {
  let titleLabel = UILabel()
  let statusLabel = UILabel()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setup()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
  }

  private func setup() {
    preservesSuperviewLayoutMargins = true
    contentView.preservesSuperviewLayoutMargins = true
    separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.numberOfLines = 0
    contentView.addSubview(titleLabel)

    statusLabel.translatesAutoresizingMaskIntoConstraints = false
    statusLabel.textColor = .systemGreen
    statusLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
    statusLabel.text = nil
    statusLabel.isHidden = true
    statusLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    statusLabel.setContentHuggingPriority(.required, for: .horizontal)
    contentView.addSubview(statusLabel)

    NSLayoutConstraint.activate([
      titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0),
      titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: statusLabel.leadingAnchor, constant: -8),
      titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 11),
      titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -11),

      statusLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      statusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15)
    ])
  }

  func configure(title: String, prepared: Bool) {
    titleLabel.text = title
    statusLabel.isHidden = prepared == false
    statusLabel.text = prepared ? "prepared" : nil
    accessoryType = .none
  }
}
