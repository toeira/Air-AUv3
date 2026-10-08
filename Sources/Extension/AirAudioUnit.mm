#import "AirAudioUnit.h"
#import <AVFoundation/AVFoundation.h>
#include "AirEngine.hpp"
#include <atomic>

@implementation AirAudioUnit {
    AUAudioUnitBus *_inputBus;
    AUAudioUnitBus *_outputBus;
    AUAudioUnitBusArray *_inputs;
    AUAudioUnitBusArray *_outputs;
    AUParameterTree *_tree;
    AVAudioPCMBuffer *_inputBuffer;
    AVAudioPCMBuffer *_outputBuffer;
    std::unique_ptr<AirEngine> _engine;
    std::atomic<float> _values[5];
    int _channels;
    float *_inputMemory[2];
}

- (instancetype)initWithComponentDescription:(AudioComponentDescription)desc
                                    options:(AudioComponentInstantiationOptions)options
                                      error:(NSError **)error {
    self = [super initWithComponentDescription:desc options:options error:error];
    if (!self) return nil;
    self.maximumFramesToRender = 4096;
    AVAudioFormat *format = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100 channels:2];
    _inputBus = [[AUAudioUnitBus alloc] initWithFormat:format error:error];
    if (!_inputBus) return nil;
    _outputBus = [[AUAudioUnitBus alloc] initWithFormat:format error:error];
    if (!_outputBus) return nil;
    _inputBus.maximumChannelCount = 2;
    _outputBus.maximumChannelCount = 2;
    _inputs = [[AUAudioUnitBusArray alloc] initWithAudioUnit:self busType:AUAudioUnitBusTypeInput busses:@[_inputBus]];
    _outputs = [[AUAudioUnitBusArray alloc] initWithAudioUnit:self busType:AUAudioUnitBusTypeOutput busses:@[_outputBus]];
    AUParameter *threshold = [AUParameterTree createParameterWithIdentifier:@"threshold" name:@"Deteção de harmónicos"
        address:0 min:-120 max:0 unit:kAudioUnitParameterUnit_Decibels unitName:nil flags:kAudioUnitParameterFlag_IsReadable|kAudioUnitParameterFlag_IsWritable valueStrings:nil dependentParameters:nil];
    AUParameter *mix = [AUParameterTree createParameterWithIdentifier:@"mix" name:@"Ar / Harmónicos"
        address:1 min:-100 max:100 unit:kAudioUnitParameterUnit_Percent unitName:nil flags:kAudioUnitParameterFlag_IsReadable|kAudioUnitParameterFlag_IsWritable valueStrings:nil dependentParameters:nil];
    AUParameter *gain = [AUParameterTree createParameterWithIdentifier:@"gain" name:@"Volume de saída"
        address:2 min:-12 max:12 unit:kAudioUnitParameterUnit_Decibels unitName:nil flags:kAudioUnitParameterFlag_IsReadable|kAudioUnitParameterFlag_IsWritable valueStrings:nil dependentParameters:nil];
    _values[0].store(-100); _values[1].store(0); _values[2].store(0); _values[3].store(20); _values[4].store(0);
    AUParameter *frequency = [AUParameterTree createParameterWithIdentifier:@"frequency" name:@"Frequência de atuação"
        address:3 min:20 max:20000 unit:kAudioUnitParameterUnit_Hertz unitName:nil flags:kAudioUnitParameterFlag_IsReadable|kAudioUnitParameterFlag_IsWritable valueStrings:nil dependentParameters:nil];
    AUParameter *wetGain = [AUParameterTree createParameterWithIdentifier:@"wetGain" name:@"Ganho da zona processada"
        address:4 min:-12 max:12 unit:kAudioUnitParameterUnit_Decibels unitName:nil flags:kAudioUnitParameterFlag_IsReadable|kAudioUnitParameterFlag_IsWritable valueStrings:nil dependentParameters:nil];
    _tree = [AUParameterTree createTreeWithChildren:@[threshold, mix, gain, frequency, wetGain]];
    __weak AirAudioUnit *weakSelf = self;
    _tree.implementorValueObserver = ^(AUParameter *parameter, AUValue value) {
        AirAudioUnit *unit = weakSelf;
        if (unit && parameter.address < 5 && std::isfinite(value))
            unit->_values[parameter.address].store(std::clamp(value, parameter.minValue, parameter.maxValue), std::memory_order_relaxed);
    };
    _tree.implementorValueProvider = ^AUValue(AUParameter *parameter) {
        AirAudioUnit *unit = weakSelf;
        return unit && parameter.address < 5 ? unit->_values[parameter.address].load(std::memory_order_relaxed) : 0;
    };
    threshold.value = -100; mix.value = 0; gain.value = 0; frequency.value = 20; wetGain.value = 0;
    return self;
}

- (AUAudioUnitBusArray *)inputBusses { return _inputs; }
- (AUAudioUnitBusArray *)outputBusses { return _outputs; }
- (AUParameterTree *)parameterTree { return _tree; }
- (NSTimeInterval)latency {
    return _engine ? (double)_engine->latency(0)/_outputBus.format.sampleRate : 0;
}

- (BOOL)allocateRenderResourcesAndReturnError:(NSError **)error {
    AVAudioFormat *input = _inputBus.format, *output = _outputBus.format;
    BOOL valid = input.channelCount == output.channelCount && input.channelCount >= 1 && input.channelCount <= 2
        && input.sampleRate == output.sampleRate && input.sampleRate >= 8000 && input.sampleRate <= 192000
        && !input.isInterleaved && !output.isInterleaved
        && input.commonFormat == AVAudioPCMFormatFloat32 && output.commonFormat == AVAudioPCMFormatFloat32;
    if (!valid) {
        if (error) *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:kAudioUnitErr_FormatNotSupported userInfo:nil];
        return NO;
    }
    if (![super allocateRenderResourcesAndReturnError:error]) return NO;
    _channels = (int)output.channelCount;
    _inputBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:input frameCapacity:self.maximumFramesToRender];
    _outputBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:output frameCapacity:self.maximumFramesToRender];
    if (!_inputBuffer || !_outputBuffer) {
        [self deallocateRenderResources];
        if (error) *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:kAudioUnitErr_FailedInitialization userInfo:nil];
        return NO;
    }
    for (int c=0; c<_channels; ++c) _inputMemory[c] = _inputBuffer.floatChannelData[c];
    try { _engine = std::make_unique<AirEngine>(output.sampleRate, _channels); }
    catch (...) {
        [self deallocateRenderResources];
        if (error) *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:kAudioUnitErr_FailedInitialization userInfo:nil];
        return NO;
    }
    return YES;
}
- (void)deallocateRenderResources {
    _engine.reset(); _inputBuffer = nil; _outputBuffer = nil;
    [super deallocateRenderResources];
}

- (NSDictionary<NSString *, id> *)fullState {
    NSMutableDictionary *state = [[super fullState] mutableCopy] ?: [NSMutableDictionary dictionary];
    state[@"AirPortParameters"] = @[@(_values[0].load()), @(_values[1].load()), @(_values[2].load()), @(_values[3].load()), @(_values[4].load())];
    return state;
}
- (void)setFullState:(NSDictionary<NSString *, id> *)state {
    [super setFullState:state];
    id stored = state[@"AirPortParameters"];
    if (![stored isKindOfClass:[NSArray class]] || [stored count] != 5) return;
    for (NSUInteger i = 0; i < 5; ++i) {
        if ([stored[i] isKindOfClass:[NSNumber class]])
            [_tree parameterWithAddress:i].value = [stored[i] floatValue];
    }
}
- (NSDictionary<NSString *, id> *)fullStateForDocument { return self.fullState; }
- (void)setFullStateForDocument:(NSDictionary<NSString *, id> *)state { self.fullState = state; }

- (AUInternalRenderBlock)internalRenderBlock {
    __unsafe_unretained AirAudioUnit *unit = self;
    return ^AUAudioUnitStatus(AudioUnitRenderActionFlags *flags, const AudioTimeStamp *timestamp,
                             AVAudioFrameCount frames, NSInteger outputBusNumber, AudioBufferList *output,
                             const AURenderEvent *events, AURenderPullInputBlock pullInput) {
        if (!unit->_engine) return kAudioUnitErr_Uninitialized;
        if (!pullInput) return kAudioUnitErr_NoConnection;
        if (outputBusNumber != 0) return kAudioUnitErr_InvalidElement;
        if (frames > unit.maximumFramesToRender) return kAudioUnitErr_TooManyFramesToProcess;
        if (output->mNumberBuffers != (UInt32)unit->_channels) return kAudioUnitErr_FormatNotSupported;
        AudioBufferList *input = unit->_inputBuffer.mutableAudioBufferList;
        for (int c=0; c<unit->_channels; ++c) {
            input->mBuffers[c].mData = unit->_inputMemory[c];
            input->mBuffers[c].mDataByteSize = frames*sizeof(float);
        }
        AUAudioUnitStatus status = pullInput(flags, timestamp, frames, 0, input);
        if (status != noErr) return status;
        for (int c=0; c<unit->_channels; ++c) {
            if (!input->mBuffers[c].mData) return kAudioUnitErr_InvalidPropertyValue;
            if (!output->mBuffers[c].mData) output->mBuffers[c].mData = unit->_outputBuffer.floatChannelData[c];
            output->mBuffers[c].mDataByteSize = frames*sizeof(float);
        }
        auto processSegment = [&](int offset, int count) {
            if (count <= 0) return;
            unit->_engine->parameters(unit->_values[0].load(std::memory_order_relaxed),
                                     unit->_values[1].load(std::memory_order_relaxed),
                                     unit->_values[2].load(std::memory_order_relaxed),
                                     unit->_values[3].load(std::memory_order_relaxed),
                                     unit->_values[4].load(std::memory_order_relaxed));
            const float *in[2] = {}; float *out[2] = {};
            for(int c=0; c<unit->_channels; ++c) {
                in[c] = static_cast<const float *>(input->mBuffers[c].mData) + offset;
                out[c] = static_cast<float *>(output->mBuffers[c].mData) + offset;
            }
            if (unit.shouldBypassEffect) {
                for(int c=0; c<unit->_channels; ++c) std::memmove(out[c], in[c], count*sizeof(float));
            } else unit->_engine->process(in, out, count);
        };
        int cursor = 0;
        for (const AURenderEvent *event=events; event; event=event->head.next) {
            if (event->head.eventType != AURenderEventParameter && event->head.eventType != AURenderEventParameterRamp) continue;
            int offset = 0;
            if (event->head.eventSampleTime != AUEventSampleTimeImmediate)
                offset = (int)std::clamp<double>(event->head.eventSampleTime - timestamp->mSampleTime, cursor, frames);
            offset = std::max(cursor, offset);
            processSegment(cursor, offset - cursor);
            cursor = offset;
            // Ramp endpoints use the DSP's own gain/frequency smoothing in v0.1.
            if (event->parameter.parameterAddress < 5 && std::isfinite(event->parameter.value))
                unit->_values[event->parameter.parameterAddress].store(event->parameter.value, std::memory_order_relaxed);
        }
        processSegment(cursor, (int)frames-cursor);
        *flags &= ~kAudioUnitRenderAction_OutputIsSilence;
        return noErr;
    };
}
@end
