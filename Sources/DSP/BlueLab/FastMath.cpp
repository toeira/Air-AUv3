// Portability replacement for the optional fastapprox dependency.
#include "FastMath.h"
#include <cmath>
FastMath::FastMath(bool) {} FastMath::~FastMath() {}
void FastMath::SetFast(bool) {}
float FastMath::log(float x){return std::log(x);} double FastMath::log(double x){return std::log(x);}
float FastMath::log10(float x){return std::log10(x);} double FastMath::log10(double x){return std::log10(x);}
float FastMath::exp(float x){return std::exp(x);} double FastMath::exp(double x){return std::exp(x);}
float FastMath::pow(float x,float p){return std::pow(x,p);} double FastMath::pow(double x,double p){return std::pow(x,p);}
