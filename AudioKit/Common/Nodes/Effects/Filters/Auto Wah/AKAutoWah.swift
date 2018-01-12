//
//  AKAutoWah.swift
//  AudioKit
//
//  Created by Aurelius Prochazka, revision history on Github.
//  Copyright © 2018 AudioKit. All rights reserved.
//

/// An automatic wah effect, ported from Guitarix via Faust.
///
open class AKAutoWah: AKNode, AKToggleable, AKComponent, AKInput {
    public typealias AKAudioUnitType = AKAutoWahAudioUnit
    /// Four letter unique description of the node
    public static let ComponentDescription = AudioComponentDescription(effect: "awah")

    // MARK: - Properties

    private var internalAU: AKAudioUnitType?
    private var token: AUParameterObserverToken?

    fileprivate var wahParameter: AUParameter?
    fileprivate var mixParameter: AUParameter?
    fileprivate var amplitudeParameter: AUParameter?

    /// Ramp Time represents the speed at which parameters are allowed to change
    @objc open dynamic var rampTime: Double = AKSettings.rampTime {
        willSet {
            internalAU?.rampTime = newValue
        }
    }

    /// Wah Amount
    @objc open dynamic var wah: Double = 0.0 {
        willSet {
            if wah == newValue {
                return
            }
            if internalAU?.isSetUp ?? false {
                if let existingToken = token {
                    wahParameter?.setValue(Float(newValue), originator: existingToken)
                    return
                }
            }
            internalAU?.setParameterImmediately(.wah, value: newValue)
        }
    }

    /// Dry/Wet Mix
    @objc open dynamic var mix: Double = 1.0 {
        willSet {
            if mix == newValue {
                return
            }
            if internalAU?.isSetUp ?? false {
                if let existingToken = token {
                    mixParameter?.setValue(Float(newValue), originator: existingToken)
                    return
                }
            }
            internalAU?.setParameterImmediately(.mix, value: newValue)
        }
    }

    /// Overall level
    @objc open dynamic var amplitude: Double = 0.1 {
        willSet {
            if amplitude == newValue {
                return
            }
            if internalAU?.isSetUp ?? false {
                if let existingToken = token {
                    amplitudeParameter?.setValue(Float(newValue), originator: existingToken)
                    return
                }
            }
            internalAU?.setParameterImmediately(.amplitude, value: newValue)
        }
    }

    /// Tells whether the node is processing (ie. started, playing, or active)
    @objc open dynamic var isStarted: Bool {
        return internalAU?.isPlaying ?? false
    }

    // MARK: - Initialization

    /// Initialize this autoWah node
    ///
    /// - Parameters:
    ///   - input: Input node to process
    ///   - wah: Wah Amount
    ///   - mix: Dry/Wet Mix
    ///   - amplitude: Overall level
    ///
    @objc public init(
        _ input: AKNode? = nil,
        wah: Double = 0.0,
        mix: Double = 1.0,
        amplitude: Double = 0.1) {

        self.wah = wah
        self.mix = mix
        self.amplitude = amplitude

        _Self.register()

        super.init()
        AVAudioUnit._instantiate(with: _Self.ComponentDescription) { [weak self] avAudioUnit in
            guard let strongSelf = self else {
                AKLog("Error: self is nil")
                return
            }
            strongSelf.avAudioNode = avAudioUnit
            strongSelf.internalAU = avAudioUnit.auAudioUnit as? AKAudioUnitType
            input?.connect(to: strongSelf)
        }

        guard let tree = internalAU?.parameterTree else {
            AKLog("Parameter Tree Failed")
            return
        }

        wahParameter = tree["wah"]
        mixParameter = tree["mix"]
        amplitudeParameter = tree["amplitude"]

        token = tree.token(byAddingParameterObserver: { [weak self] _, _ in

            guard let _ = self else {
                AKLog("Unable to create strong reference to self")
                return
            } // Replace _ with strongSelf if needed
            DispatchQueue.main.async {
                // This node does not change its own values so we won't add any
                // value observing, but if you need to, this is where that goes.
            }
        })

        self.internalAU?.setParameterImmediately(.wah, value: wah)
        self.internalAU?.setParameterImmediately(.mix, value: mix)
        self.internalAU?.setParameterImmediately(.amplitude, value: amplitude)
    }

    // MARK: - Control

    /// Function to start, play, or activate the node, all do the same thing
    @objc open func start() {
        internalAU?.start()
    }

    /// Function to stop or bypass the node, both are equivalent
    @objc open func stop() {
        internalAU?.stop()
    }
}

