#pragma once
#include "AirProcess3.h"
#include <memory>
#include <atomic>
#include "CrossoverSplitterNBands4.h"
class AirEngine {
 int channels_; double rate_; int fftSize_=2048;
 std::vector<std::unique_ptr<AirProcess3>> processors_;
 std::unique_ptr<FftProcessObj16> fft_;
 std::vector<WDL_TypedBuf<double>> in_, out_, side_;
 double gain_=1., gainTarget_=1., wetGain_=1., wetGainTarget_=1., cutoff_=20., cutoffTarget_=20.;
 std::vector<std::unique_ptr<CrossoverSplitterNBands4>> splitIn_,splitOut_;
 std::vector<std::vector<double>> delay_;
 int delayPos_=0;
public:
 AirEngine(double sampleRate,int channels);
 int latency(int frames=512) const;
 void parameters(float threshold,float mix,float gainDB,float cutoff=20,float wetGainDB=0);
 void process(const float* const* input,float* const* output,int frames);
};
