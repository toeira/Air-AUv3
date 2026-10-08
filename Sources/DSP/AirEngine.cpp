#include "AirEngine.hpp"
#include <mutex>
AirEngine::AirEngine(double sr,int ch):channels_(ch),rate_(sr),in_(ch),out_(ch){
 static std::once_flag once;std::call_once(once,[]{FftProcessObj16::Init();});
 if(sr>48000.) fftSize_=4096;
 std::vector<ProcessObj*> raw;
 for(int i=0;i<ch;++i){processors_.emplace_back(new AirProcess3(fftSize_,4,1,sr));
  processors_.back()->SetEnableSum(false);processors_.back()->SetUseSoftMasks(false);raw.push_back(processors_.back().get());
  in_[i].Resize(4096);out_[i].Resize(4096);
  double cutoff=20;
  splitIn_.emplace_back(new CrossoverSplitterNBands4(2,&cutoff,sr));
  splitOut_.emplace_back(new CrossoverSplitterNBands4(2,&cutoff,sr));
  delay_.emplace_back(fftSize_,0.);}
 fft_.reset(new FftProcessObj16(raw,ch,0,fftSize_,4,1,sr));
 fft_->SetAnalysisWindow(-1,FftProcessObj16::WindowHanning);
 fft_->SetSynthesisWindow(-1,FftProcessObj16::WindowHanning);
 fft_->SetKeepSynthesisEnergy(-1,false);
 parameters(-100,0,0);
}
int AirEngine::latency(int n)const{return fft_->ComputeLatency(n);}
void AirEngine::parameters(float t,float m,float g,float cutoff,float wetGain){
 t=std::clamp(t,-120.f,0.f);m=std::clamp(m,-100.f,100.f);g=std::clamp(g,-12.f,12.f);
 for(auto& p:processors_){p->SetThreshold(t);p->SetMix(m/100.);}
 gainTarget_=std::pow(10.,g/20.);
 cutoffTarget_=std::clamp(double(cutoff),20.,std::min(20000.,rate_*0.45));
 wetGainTarget_=std::pow(10.,std::clamp(wetGain,-12.f,12.f)/20.);
}
void AirEngine::process(const float* const* input,float* const* output,int n){
 if(n<=0)return;
 for(int c=0;c<channels_;++c){in_[c].Resize(n);out_[c].Resize(n);for(int j=0;j<n;++j)in_[c].Get()[j]=input[c][j];}
 fft_->Process(in_,side_,&out_);
 cutoff_ += (cutoffTarget_-cutoff_)*(1.-std::exp(-n/(rate_*0.28)));
 for(int c=0;c<channels_;++c){splitIn_[c]->SetCutoffFreq(0,cutoff_);splitOut_[c]->SetCutoffFreq(0,cutoff_);}
 const double smooth=1.-std::exp(-1./(rate_*0.01));
 for(int j=0;j<n;++j){
  gain_+=(gainTarget_-gain_)*smooth;wetGain_+=(wetGainTarget_-wetGain_)*smooth;
  for(int c=0;c<channels_;++c){double dry[2],wet[2];
   splitIn_[c]->Split(in_[c].Get()[j],dry);splitOut_[c]->Split(out_[c].Get()[j],wet);
   double lo=delay_[c][delayPos_];delay_[c][delayPos_]=dry[0];
   output[c][j]=float((lo+wet[1]*wetGain_)*gain_);
  }
  delayPos_=(delayPos_+1)%fftSize_;
 }
}
