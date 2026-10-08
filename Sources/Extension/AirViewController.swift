import UIKit
import AudioToolbox
import CoreAudioKit

@objc(AirViewController)
final class AirViewController: AUViewController, AUAudioUnitFactory {
    private var unit: AirAudioUnit?
    private var sliders: [UISlider] = []
    private var labels: [UILabel] = []
    private var timer: Timer?

    func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
        let audioUnit = try AirAudioUnit(componentDescription: componentDescription, options: [])
        unit = audioUnit
        DispatchQueue.main.async { [weak self] in self?.refresh() }
        return audioUnit
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.08, alpha: 1)
        preferredContentSize = CGSize(width: 560, height: 360)
        let stack = UIStackView()
        stack.axis = .vertical; stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -12)
        ])
        let title = UILabel()
        title.text = "AIR · BlueLab DSP"; title.textColor = .white
        title.font = .boldSystemFont(ofSize: 21)
        stack.addArrangedSubview(title)
        for index in 0..<5 {
            let row = UIStackView(); row.axis = .horizontal; row.spacing = 12
            let label = UILabel(); label.textColor = .white; label.font = .systemFont(ofSize: 13)
            label.widthAnchor.constraint(equalToConstant: 165).isActive = true
            let slider = UISlider(); slider.tag = index; slider.tintColor = .systemTeal
            slider.minimumValue = [-120, -100, -12, 0, -12][index]
            slider.maximumValue = [0, 100, 12, 1, 12][index]
            slider.value = [-100, 0, 0, 0, 0][index]
            slider.addTarget(self, action: #selector(changed(_:)), for: .valueChanged)
            row.addArrangedSubview(label); row.addArrangedSubview(slider)
            row.heightAnchor.constraint(equalToConstant: 38).isActive = true
            labels.append(label); sliders.append(slider); stack.addArrangedSubview(row)
        }
        let hint = UILabel(); hint.text = "Mistura: −100 = ar · 0 = ambos · +100 = harmónicos"
        hint.textColor = .lightGray; hint.font = .systemFont(ofSize: 12); hint.numberOfLines = 2
        stack.addArrangedSubview(hint)
        refresh()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in self?.refresh() }
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated); timer?.invalidate(); timer = nil
    }
    deinit { timer?.invalidate() }
    @objc private func changed(_ sender: UISlider) {
        unit?.parameterTree?.parameter(withAddress: AUParameterAddress(sender.tag))?.value = sender.tag == 3 ? 20 * pow(1000, sender.value) : sender.value
        updateLabel(sender.tag, sender.tag == 3 ? 20 * pow(1000, sender.value) : sender.value)
    }
    private func refresh() {
        for index in sliders.indices {
            let value = unit?.parameterTree?.parameter(withAddress: AUParameterAddress(index))?.value ?? sliders[index].value
            if !sliders[index].isTracking { sliders[index].value = index == 3 ? log(max(value, 20) / 20) / log(1000) : value }
            updateLabel(index, value)
        }
    }
    private func updateLabel(_ index: Int, _ value: Float) {
        let names = ["Deteção", "Ar / Harmónicos", "Saída", "Atuação acima de", "Ganho processado"]
        labels[index].text = String(format: "%@: %.1f %@", names[index], value, index == 1 ? "%" : (index == 3 ? "Hz" : "dB"))
    }
}
