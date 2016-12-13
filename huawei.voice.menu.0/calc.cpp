#include<iostream>

using namespace std;
double calc(double,double);

int main() {
    cout << calc(2,3) << "\n";
}

double calc(double a,double b){
	return a+b;
}