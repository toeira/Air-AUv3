#include "AirEngine.hpp"
#include <iostream>
#include <random>
#include <stdexcept>
#include <numeric>
int main(){
 for(double sr:{44100.,48000.,96000.})for(int channels:{1,2}){
  AirEngine engine(sr,channels);std::mt19937 gen(22);std::normal_distribution<float> noise(0,.03);
  std::vector<float> in[2],out[2];const float* ip[2];float* op[2];double energy=0;int nonzero=0;
  int sampleIndex=0;
  for(int b=0;b<160;++b){int n=std::vector<int>{1,64,128,256,512,1024,4096,137}[b%8];
   for(int c=0;c<channels;++c){in[c].resize(n);out[c].resize(n);ip[c]=in[c].data();op[c]=out[c].data();
    for(int i=0;i<n;++i)in[c][i]=.2f*std::sin(2*3.141592653589793*440*(sampleIndex+i)/sr)+noise(gen);}
   engine.parameters(-100,b<50?0:(b<100?-100:100),0,b<120?20:1000,b<120?0:6);engine.process(ip,op,n);
   sampleIndex+=n;
   for(int c=0;c<channels;++c)for(float x:out[c]){if(!std::isfinite(x)||std::abs(x)>5)throw std::runtime_error("invalid output");energy+=x*x;if(x!=0)++nonzero;}
  }
  if(nonzero<1000||energy<1)throw std::runtime_error("silent output");
  std::cout<<sr<<" Hz "<<channels<<" channels: finite output, energy="<<energy<<", latency="<<engine.latency()<<" samples\n";
 }
 double amplitudes[3]={};
 for(int mode=0;mode<3;++mode){
  AirEngine engine(48000,1);engine.parameters(-100,mode==0?0:(mode==1?-100:100),0);
  std::mt19937 gen(99);std::normal_distribution<float> noise(0,.03);
  float input[256],output[256];const float* ip[]={input};float* op[]={output};
  double sine=0,cosine=0;int counted=0;
  for(int block=0;block<240;++block){
   for(int i=0;i<256;++i)input[i]=.2f*std::sin(2*3.141592653589793*440*(block*256+i)/48000)+noise(gen);
   engine.process(ip,op,256);
   if(block>40)for(int i=0;i<256;++i){double phase=2*3.141592653589793*440*(block*256+i)/48000;
    sine+=output[i]*std::sin(phase);cosine+=output[i]*std::cos(phase);++counted;}
  }
  amplitudes[mode]=2*std::hypot(sine,cosine)/counted;
 }
 std::cout<<"440 Hz amplitude: both="<<amplitudes[0]<<", air="<<amplitudes[1]<<", harmonic="<<amplitudes[2]<<"\n";
 if(amplitudes[2]<.1 || amplitudes[1]>.5*amplitudes[2])throw std::runtime_error("harmonic/air separation failed");
}
