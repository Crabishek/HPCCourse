#include <stdio.h>
#include <math.h>
#include <time.h>
#include <unistd.h>
#include <cuda_runtime_api.h>
#include <errno.h>
#include <unistd.h>

/******************************************************************************
 * This program takes an initial estimate of m and c and finds the associated 
 * rms error. It is then as a base to generate and evaluate 8 new estimates, 
 * which are steps in different directions in m-c space. The best estimate is 
 * then used as the base for another iteration of "generate and evaluate". This 
 * continues until none of the new estimates are better than the base. This is
 * a gradient search for a minimum in mc-space.
 * 
 * To compile:
 *   cc -o lr_coursework lr_coursework.c -lm
 * 
 * To run:
 *   ./lr_coursework
 * 
 * Dr Kevan Buckley, University of Wolverhampton, 2018
 *****************************************************************************/

typedef struct point_t {
  double x;
  double y;
} point_t;

int n_data = 1000;
__device__ int d_n_data = 1000;


point_t data[] = {
  {77.91,137.94},{73.55,140.19},{67.73,103.18},{72.21,107.69},
  {65.87,111.92},{69.66,113.91},{76.72,110.53},{70.64,116.64},
  {85.61,124.05},{76.77,121.42},{76.49,110.56},{69.74,122.83},
  {82.22,117.16},{30.49,71.38},{26.76,78.09},{60.10,113.07},
  { 6.45,48.40},{28.23,62.23},{16.98,57.19},{42.86,72.84},
  {45.90,101.80},{11.00,48.54},{88.36,140.39},{10.97,56.44},
  {33.41,63.81},{40.15,88.93},{41.16,94.70},{ 8.27,44.49},
  {40.10,88.81},{14.94,68.41},{94.69,130.29},{54.04,99.42},
  {96.78,144.92},{34.64,69.07},{68.88,111.93},{69.30,119.68},
  {64.35,128.70},{13.22,64.68},{94.53,152.09},{37.79,92.85},
  {29.84,87.18},{19.43,57.34},{49.04,95.81},{38.11,111.29},
  {61.85,120.56},{45.89,93.11},{21.28,66.51},{42.66,74.88},
  {86.60,133.95},{32.28,81.48},{45.65,85.03},{70.93,104.05},
  {27.47,61.30},{27.89,84.13},{45.54,79.23},{26.27,74.84},
  {99.30,147.19},{71.25,105.51},{ 2.30,46.45},{26.51,61.82},
  {41.32,71.59},{43.62,82.30},{73.94,121.04},{77.37,138.14},
  {65.54,103.86},{51.71,90.47},{45.09,80.79},{56.73,94.98},
  {35.46,67.69},{15.96,43.84},{69.51,97.47},{76.31,115.14},
  {50.76,111.88},{ 8.94,43.42},{94.76,130.50},{11.18,52.89},
  {34.86,80.62},{37.48,79.21},{ 7.59,54.55},{27.57,76.34},
  {57.26,87.54},{ 9.36,53.07},{47.67,91.40},{48.61,78.84},
  {42.20,95.36},{69.48,116.91},{56.63,109.48},{63.82,103.96},
  {11.35,42.22},{28.48,68.38},{60.46,106.86},{56.93,103.53},
  {74.62,121.94},{93.32,141.87},{77.71,132.25},{12.04,36.33},
  {86.85,135.93},{99.24,137.68},{24.16,79.63},{14.75,54.94},
  {21.01,54.39},{70.57,106.15},{33.02,61.07},{90.59,137.18},
  {62.71,97.37},{38.43,87.14},{55.08,96.69},{99.10,162.52},
  {77.24,129.84},{31.20,70.54},{75.41,116.41},{23.94,54.01},
  { 6.83,44.58},{44.52,92.93},{78.11,110.63},{92.41,134.57},
  {61.06,110.49},{58.22,80.87},{81.40,118.57},{83.75,143.43},
  { 4.82,55.24},{57.03,102.68},{26.86,78.80},{37.38,77.85},
  {58.54,119.47},{56.66,90.04},{54.93,98.51},{60.22,94.79},
  {80.88,120.59},{21.00,56.00},{63.01,104.75},{ 1.61,33.15},
  {94.90,139.36},{95.17,153.42},{38.37,68.95},{66.06,109.97},
  {68.45,112.16},{74.99,125.06},{49.64,93.96},{15.95,29.82},
  { 5.04,42.00},{98.76,137.21},{74.07,126.20},{68.65,128.60},
  {11.38,26.96},{49.95,82.69},{29.04,74.89},{16.38,63.83},
  {59.04,109.53},{27.32,71.71},{39.51,101.93},{54.04,96.36},
  {51.50,100.11},{25.88,63.72},{76.07,112.84},{85.46,129.42},
  { 3.80,40.40},{57.09,110.76},{59.19,96.37},{76.34,124.58},
  {38.28,91.58},{72.14,111.75},{88.50,132.91},{94.21,141.83},
  { 2.43,32.33},{62.47,115.70},{24.78,59.55},{14.39,64.41},
  {99.32,140.63},{ 6.44,49.49},{ 2.25,29.16},{19.09,44.98},
  { 6.33,48.74},{54.46,91.56},{68.23,117.61},{27.76,77.29},
  {78.68,118.79},{39.96,84.11},{99.49,146.02},{46.24,99.64},
  { 9.18,38.93},{35.33,94.25},{95.52,149.63},{56.44,99.26},
  {10.70,60.09},{23.20,52.34},{ 4.34,34.46},{58.07,108.44},
  {33.12,87.11},{72.71,116.57},{ 8.74,47.56},{ 0.04,51.06},
  {26.39,55.02},{41.34,97.48},{96.12,138.97},{81.76,128.23},
  {93.98,150.40},{77.63,137.75},{59.95,117.56},{92.74,133.49},
  {88.40,144.82},{72.31,110.11},{61.92,101.44},{27.51,74.96},
  {61.45,95.72},{73.46,117.17},{62.02,102.17},{59.49,114.88},
  {18.03,47.92},{36.98,80.51},{24.98,57.81},{22.88,49.89},
  {89.51,136.78},{46.50,91.37},{58.98,95.67},{48.35,83.96},
  {73.68,125.13},{44.09,106.47},{32.16,67.74},{93.39,146.45},
  {13.34,35.70},{74.02,111.39},{84.35,134.19},{72.87,106.49},
  {80.02,116.40},{79.03,134.19},{ 9.43,73.06},{57.48,122.57},
  {90.90,127.78},{42.58,83.98},{57.70,96.29},{71.45,108.44},
  {35.14,84.38},{94.49,130.20},{22.54,89.12},{25.76,79.00},
  {54.87,93.03},{81.53,123.81},{34.15,77.98},{70.97,116.78},
  {13.18,47.54},{63.55,124.59},{62.49,107.07},{84.30,138.60},
  {15.66,63.61},{30.99,87.18},{33.96,68.64},{ 2.19,46.07},
  {48.87,92.79},{79.79,131.08},{71.29,120.93},{72.16,132.56},
  {17.13,51.90},{28.39,71.37},{94.06,133.31},{17.60,43.10},
  {77.55,145.59},{93.45,140.12},{12.55,53.67},{62.44,96.08},
  {40.29,84.88},{26.65,69.78},{94.37,136.47},{32.37,66.81},
  {59.10,99.68},{74.29,128.55},{21.33,69.52},{51.34,88.05},
  {99.82,146.42},{47.96,80.59},{81.11,144.49},{94.90,153.29},
  {54.00,103.65},{53.53,87.53},{54.91,90.78},{ 5.14,36.78},
  {29.93,69.98},{ 3.08,37.13},{94.13,150.87},{10.46,52.34},
  {36.77,95.13},{57.38,95.64},{89.28,127.06},{ 7.91,45.51},
  {72.55,125.14},{83.21,133.87},{70.89,113.46},{32.39,82.07},
  {54.13,100.86},{68.83,116.81},{64.48,105.76},{33.59,83.13},
  {46.38,84.07},{90.03,120.24},{ 1.77,30.89},{67.22,119.87},
  {39.33,84.74},{42.47,101.74},{95.05,136.38},{48.02,104.48},
  {49.45,101.45},{82.31,122.99},{34.06,65.00},{91.26,121.28},
  { 0.41,32.00},{67.71,94.28},{99.76,133.29},{77.93,125.82},
  { 1.68,46.34},{45.04,107.98},{81.64,110.16},{72.74,117.13},
  {84.24,107.66},{81.42,125.84},{57.07,100.89},{85.54,126.36},
  {41.28,77.43},{54.28,95.17},{76.96,142.41},{70.96,93.42},
  { 2.31,43.37},{84.15,131.81},{39.52,84.19},{33.53,61.80},
  {61.74,92.17},{21.04,56.67},{ 8.18,58.27},{ 4.70,44.13},
  {50.57,95.90},{27.39,69.58},{16.06,30.97},{45.69,91.88},
  {86.56,132.60},{40.11,67.72},{27.03,67.79},{34.12,72.91},
  {95.42,146.35},{47.82,98.04},{88.28,142.05},{39.46,72.98},
  {33.18,70.94},{64.41,120.27},{83.11,136.72},{49.37,78.60},
  {51.86,83.64},{75.19,118.96},{75.39,124.65},{45.93,77.95},
  { 5.86,46.50},{47.88,98.78},{28.13,64.80},{40.09,91.03},
  {81.07,143.02},{79.79,102.30},{42.99,85.52},{36.20,72.76},
  {99.67,156.20},{64.44,110.66},{94.63,138.33},{28.42,75.97},
  {54.67,87.20},{96.62,154.09},{23.70,62.38},{38.67,78.86},
  {22.09,56.57},{29.19,70.08},{ 9.39,63.72},{20.57,46.94},
  {77.93,123.66},{54.94,94.95},{95.31,129.18},{10.14,49.72},
  {48.01,76.86},{62.66,128.28},{ 3.51,48.10},{50.77,83.73},
  {60.45,116.21},{ 8.07,57.61},{85.27,152.01},{63.39,109.60},
  {86.87,129.76},{ 3.76,36.44},{93.11,149.12},{69.63,114.32},
  {88.45,131.41},{90.76,123.43},{69.16,123.60},{10.23,37.67},
  {68.41,122.94},{28.20,56.51},{39.87,79.05},{51.55,85.21},
  {47.52,95.17},{25.61,75.33},{85.93,136.70},{30.53,57.66},
  { 3.47,49.10},{97.05,145.27},{67.53,102.44},{74.58,121.92},
  { 1.84,46.71},{20.51,53.47},{67.26,97.46},{49.67,90.19},
  {36.84,83.86},{28.66,62.86},{40.13,90.36},{93.40,140.55},
  {58.51,96.91},{79.61,93.98},{85.29,133.17},{91.11,142.37},
  {97.26,154.56},{58.64,95.55},{78.03,125.40},{45.37,78.87},
  {95.15,138.71},{64.43,123.91},{68.30,119.83},{84.59,124.52},
  {36.37,80.59},{70.22,96.59},{30.18,75.66},{95.22,133.93},
  {29.80,73.46},{36.03,68.69},{22.55,60.53},{92.75,139.88},
  {67.76,113.62},{91.84,133.75},{66.37,119.44},{ 1.67,25.11},
  {25.90,55.54},{54.07,91.65},{33.45,91.06},{10.93,58.02},
  {80.08,129.17},{ 8.88,57.18},{40.95,80.77},{ 5.92,28.75},
  {30.67,77.57},{40.89,79.48},{97.27,158.36},{81.72,123.87},
  {23.01,52.68},{53.24,101.99},{97.87,137.07},{57.48,101.19},
  {98.71,148.21},{71.11,112.95},{57.69,83.01},{92.05,131.64},
  {44.24,97.84},{94.38,147.34},{18.31,47.47},{53.40,87.97},
  {37.76,79.24},{25.34,66.33},{48.52,92.49},{74.42,126.63},
  { 9.16,35.22},{10.12,61.68},{82.08,127.94},{55.82,115.67},
  {94.99,158.31},{52.50,98.22},{33.08,85.34},{44.86,71.11},
  {63.03,109.30},{30.23,63.91},{42.90,99.14},{13.49,61.23},
  {34.00,78.21},{20.83,64.89},{56.70,110.87},{29.28,62.25},
  {39.06,70.14},{41.13,75.52},{15.31,48.77},{47.86,90.13},
  {81.72,124.72},{26.99,75.25},{79.69,124.73},{19.90,55.67},
  {31.05,71.45},{73.25,108.77},{30.93,71.27},{13.94,57.58},
  {96.73,123.05},{ 0.36,27.96},{55.29,98.98},{35.61,76.60},
  {36.07,97.21},{32.71,67.50},{55.60,108.66},{54.62,96.93},
  {18.98,55.79},{11.90,52.95},{10.51,44.69},{64.28,107.92},
  {83.08,122.82},{27.91,83.34},{84.34,145.33},{86.00,142.97},
  {43.56,88.18},{78.20,111.30},{81.74,128.23},{65.69,113.52},
  {74.03,128.98},{45.63,74.61},{98.51,156.36},{38.19,90.32},
  {68.10,117.84},{37.99,62.93},{90.85,143.03},{22.43,63.57},
  {13.21,38.92},{91.97,142.82},{62.72,115.55},{67.26,126.35},
  {53.05,85.26},{93.97,142.15},{58.59,115.37},{91.96,134.64},
  {27.86,75.95},{54.72,112.05},{24.52,80.58},{ 6.18,29.76},
  {31.05,69.21},{63.08,112.53},{70.10,94.71},{76.97,129.39},
  {15.09,50.83},{27.21,71.13},{ 6.49,46.66},{43.93,98.49},
  { 7.49,48.51},{16.83,47.93},{38.64,67.91},{50.04,74.44},
  {40.82,90.82},{ 6.80,32.81},{63.64,93.63},{60.60,109.89},
  {58.90,101.00},{86.48,145.07},{ 7.15,41.21},{28.15,67.43},
  {64.20,101.33},{80.75,115.35},{40.40,79.91},{34.78,84.96},
  {69.88,121.96},{16.66,73.49},{10.06,58.83},{27.96,64.46},
  {53.84,91.50},{87.87,146.70},{49.03,82.12},{76.03,111.50},
  {29.03,55.19},{22.44,53.09},{82.82,132.99},{95.90,136.32},
  {37.21,71.98},{42.25,104.38},{77.76,134.68},{27.48,79.72},
  { 8.20,54.46},{22.64,70.60},{56.39,93.04},{41.02,79.64},
  {85.82,147.33},{46.10,86.18},{73.35,120.35},{35.86,84.81},
  {79.61,132.16},{33.31,61.78},{86.83,125.84},{15.61,38.11},
  {60.07,89.20},{97.80,132.30},{ 6.66,39.04},{ 1.06,21.28},
  {17.84,65.02},{52.00,95.55},{81.65,118.00},{76.78,132.88},
  {97.72,151.72},{61.43,104.38},{64.39,107.58},{22.55,73.41},
  {54.48,113.54},{64.33,113.33},{ 8.85,29.80},{63.27,114.98},
  {26.79,75.91},{ 9.12,63.89},{ 2.82,40.76},{17.92,56.66},
  {24.75,76.14},{31.34,73.34},{32.78,76.99},{10.92,36.93},
  {26.73,64.14},{10.88,58.58},{96.82,140.90},{77.88,134.50},
  {97.84,134.78},{42.59,80.77},{17.50,59.90},{93.79,135.44},
  {77.77,115.47},{51.33,86.67},{12.70,32.70},{60.72,103.85},
  {31.69,60.38},{83.72,111.31},{61.48,107.22},{88.83,123.38},
  {12.92,56.40},{35.71,65.41},{24.00,48.01},{88.44,139.09},
  { 0.23,34.14},{38.85,77.55},{45.11,90.53},{29.25,65.54},
  {61.30,99.63},{14.23,58.27},{30.31,75.98},{76.70,119.00},
  {32.24,62.54},{24.71,62.05},{78.14,129.60},{23.29,68.88},
  {72.49,106.79},{79.14,120.16},{16.74,58.14},{79.03,120.90},
  { 2.20,47.86},{21.38,71.37},{38.66,101.19},{91.29,134.26},
  {79.56,143.14},{ 0.64,17.91},{38.24,73.91},{43.36,101.26},
  {75.76,128.57},{61.91,97.17},{ 2.87,39.03},{76.97,129.62},
  {56.48,95.38},{24.98,72.11},{ 0.31,28.92},{65.32,95.59},
  {78.66,112.24},{ 9.61,55.49},{17.51,62.49},{44.86,84.27},
  {56.82,108.95},{88.90,127.31},{77.91,102.26},{59.98,87.42},
  {63.04,94.23},{36.46,88.09},{72.96,120.36},{94.22,156.65},
  {25.16,74.23},{87.33,131.71},{85.61,129.34},{62.29,113.26},
  {36.64,84.47},{86.47,129.95},{24.83,55.85},{36.88,91.52},
  { 9.60,44.53},{ 8.29,29.05},{77.87,117.78},{ 3.65,57.62},
  {29.50,66.42},{82.11,135.13},{87.94,131.08},{19.22,51.06},
  {77.14,137.18},{36.06,85.33},{11.79,65.84},{95.87,122.45},
  {86.82,130.26},{66.64,102.41},{84.49,124.25},{58.31,85.27},
  { 6.65,50.38},{92.34,130.07},{30.25,69.84},{44.33,76.39},
  {11.95,51.41},{41.72,105.88},{59.94,109.36},{13.56,49.44},
  {60.66,117.25},{38.59,85.94},{48.00,100.76},{ 7.14,52.20},
  {16.88,50.44},{ 3.07,46.82},{93.55,122.74},{88.41,126.77},
  {70.37,122.32},{44.80,89.11},{29.92,61.25},{97.73,144.98},
  {37.63,74.16},{51.59,109.22},{43.66,80.18},{95.37,151.05},
  {79.07,135.38},{19.82,65.97},{90.53,115.60},{81.58,123.75},
  {28.89,66.95},{24.30,77.77},{89.15,126.12},{27.07,74.44},
  { 7.44,33.59},{26.16,70.17},{90.96,128.55},{39.91,75.53},
  {65.45,93.73},{ 7.68,32.59},{34.21,86.35},{36.14,70.00},
  {48.50,82.20},{96.88,140.90},{61.67,97.25},{54.20,102.73},
  {20.02,65.41},{10.62,55.73},{48.33,87.72},{17.04,50.61},
  {31.04,61.63},{10.91,53.43},{50.99,86.70},{65.09,88.77},
  {89.08,146.30},{80.78,121.86},{14.37,58.44},{ 9.39,40.79},
  {20.67,57.29},{ 9.08,68.40},{47.52,95.72},{71.48,117.41},
  {11.62,52.50},{ 6.70,54.06},{62.83,122.69},{74.72,142.22},
  { 1.67,38.64},{ 0.16,38.41},{97.31,150.19},{42.77,77.46},
  {22.14,55.75},{83.46,136.50},{61.77,96.62},{ 0.06,30.09},
  {97.36,143.75},{70.03,125.10},{79.57,127.39},{83.54,127.26},
  {42.85,92.36},{17.24,58.84},{53.25,88.51},{ 2.56,44.53},
  {71.72,121.73},{85.75,130.90},{47.62,101.11},{15.78,63.30},
  { 6.43,45.38},{16.56,39.99},{61.06,110.65},{36.67,93.80},
  {14.19,44.88},{ 0.68,49.49},{ 7.30,34.40},{ 8.88,50.84},
  {95.16,130.83},{71.87,122.62},{20.10,57.88},{94.33,140.90},
  {32.76,61.94},{53.70,96.13},{70.60,129.76},{71.13,118.00},
  {12.84,51.27},{13.24,56.18},{ 9.13,47.39},{80.29,139.56},
  {21.04,65.87},{67.74,101.56},{36.60,68.50},{40.76,91.95},
  {52.31,98.09},{18.87,47.54},{70.72,99.96},{92.31,125.51},
  {66.83,110.26},{ 0.45,28.87},{53.29,92.35},{19.20,56.25},
  {64.75,97.41},{98.02,156.22},{83.66,137.30},{50.42,95.68},
  {67.75,114.35},{ 0.62,40.65},{79.83,120.17},{89.79,132.11},
  {36.21,68.02},{40.99,83.14},{93.31,158.32},{14.33,52.24},
  {25.40,84.95},{ 1.54,32.14},{52.78,102.58},{92.88,140.40},
  { 3.40,46.06},{28.56,55.92},{81.67,114.32},{41.98,78.43},
  { 2.41,40.92},{87.39,129.75},{24.11,59.23},{70.33,108.86},
  {97.45,170.97},{51.47,73.41},{49.55,95.09},{62.37,113.87},
  { 9.01,40.54},{95.06,120.59},{75.97,133.00},{ 4.72,58.11},
  {18.99,59.83},{47.94,77.34},{79.85,106.00},{28.92,77.12},
  {45.71,84.34},{39.43,79.34},{52.63,108.60},{49.54,93.24},
  {59.78,95.58},{18.71,62.50},{46.50,98.75},{52.82,85.80},
  {72.43,131.61},{36.02,76.32},{46.58,101.85},{21.49,60.48},
  { 6.05,45.53},{90.92,138.53},{55.96,106.46},{84.69,135.08},
  {28.24,68.22},{39.17,94.71},{ 6.92,56.07},{49.42,109.44},
  {22.91,49.83},{36.70,70.34},{12.48,53.18},{38.64,78.95},
  {83.58,113.92},{10.45,32.71},{65.88,102.70},{40.93,91.07},
  { 3.45,27.36},{24.43,46.10},{92.16,149.14},{21.86,60.48},
  {67.09,109.56},{22.22,71.28},{32.01,67.43},{12.73,44.50},
  {75.37,116.20},{85.03,129.18},{66.38,103.56},{39.10,95.26},
  {11.80,54.21},{18.01,52.89},{21.36,68.01},{ 1.58,47.56},
  {30.67,73.12},{35.21,71.88},{22.38,64.38},{22.65,59.59},
  {41.35,67.34},{32.20,70.19},{81.08,133.90},{86.97,136.75},
  {17.44,60.37},{80.92,133.81},{99.32,144.20},{27.09,75.37},
  {48.93,82.31},{67.78,121.54},{32.13,83.10},{35.53,89.31},
  {40.21,54.98},{68.96,126.59},{ 4.47,30.15},{25.80,76.93},
  {26.78,66.78},{41.94,90.81},{44.21,75.12},{61.65,103.95},
  {99.04,137.83},{82.92,125.62},{62.11,115.28},{63.62,113.02},
  {26.20,73.38},{28.14,77.48},{28.19,74.24},{10.03,52.34},
  {64.55,109.04},{70.74,105.96},{60.22,92.48},{10.32,72.87},
  {33.34,57.89},{35.27,65.05},{45.76,116.58},{ 0.49,57.86},
  {66.70,109.27},{55.73,103.89},{44.45,90.52},{38.56,77.80},
  {82.45,120.05},{66.12,113.99},{12.53,66.87},{ 5.50,48.99},
  {74.01,115.15},{30.31,72.87},{35.83,71.68},{37.14,95.23},
  {51.21,99.36},{23.85,69.26},{26.89,75.49},{13.59,59.16},
  {25.22,68.93},{52.73,109.21},{60.45,113.81},{51.60,103.04},
  {79.96,123.55},{46.98,97.77},{ 1.66,21.38},{75.71,137.06},
  {33.47,70.29},{ 1.51,35.75},{ 0.74,35.19},{62.56,88.66},
  {87.96,135.91},{62.35,105.98},{12.09,62.14},{96.99,151.92},
  {74.71,134.08},{87.17,134.74},{12.05,34.79},{32.97,78.39},
  { 2.80,51.64},{26.75,67.52},{40.96,69.15},{78.20,123.24},
  {29.55,66.86},{92.50,135.15},{44.16,90.03},{68.10,115.91},
  { 7.05,36.94},{ 1.31,34.46},{42.44,100.45},{12.63,42.62},
  {30.10,87.86},{47.35,91.17},{18.59,50.43},{64.59,98.09},
  {54.62,77.52},{67.17,91.15},{37.10,71.55},{86.15,139.15},
  {23.17,58.38},{58.31,97.30},{40.06,66.65},{89.85,145.61},
  {54.43,85.60},{60.17,110.33},{16.25,57.61},{60.56,106.49},
  { 7.44,51.15},{59.46,114.06},{44.40,81.99},{14.29,45.65},
  { 8.30,44.93},{66.49,111.11},{78.69,118.62},{60.81,116.74}
};

double residual_error(double x, double y, double m, double c) {
  double e = (m * x) + c - y;
  return e * e;
}

__device__ double d_residual_error(double x, double y, double m, double c) {
  double e = (m * x) + c - y;
  return e * e;
}

double rms_error(double m, double c) {
  int i;
  double mean;
  double error_sum = 0;
  
  for(i=0; i<n_data; i++) {
    error_sum += residual_error(data[i].x, data[i].y, m, c);
  }
  
  mean = error_sum / n_data;
  
  return sqrt(mean);
}

__global__ void d_rms_error(double *m, double *c, double *error_sum_arr, point_t *d_data) {
	/*
		Calculate the current index by using:
		- The thread id
		- The block id
		- The number of threads per block
	*/
	int i = threadIdx.x + blockIdx.x * blockDim.x;

	//Work out the error sum 1000 times and store them in an array.
  error_sum_arr[i] = d_residual_error(d_data[i].x, d_data[i].y, *m, *c);
}

int time_difference(struct timespec *start, struct timespec *finish, 
                              long long int *difference) {
  long long int ds =  finish->tv_sec - start->tv_sec; 
  long long int dn =  finish->tv_nsec - start->tv_nsec; 

  if(dn < 0 ) {
    ds--;
    dn += 1000000000; 
  } 
  *difference = ds * 1000000000 + dn;
  return !(*difference > 0);
}

int main() {
  int i;
  double bm = 1.3;
  double bc = 10;
  double be;
  double dm[8];
  double dc[8];
  double e[8];
  double step = 0.01;
  double best_error = 999999999;
  int best_error_i;
  int minimum_found = 0;
  
  double om[] = {0,1,1, 1, 0,-1,-1,-1};
  double oc[] = {1,1,0,-1,-1,-1, 0, 1};

	struct timespec start, finish;   
  long long int time_elapsed;

	//Get the system time before we begin the linear regression.
  clock_gettime(CLOCK_MONOTONIC, &start);

	cudaError_t error;

	//Device variables
	double *d_dm;
  double *d_dc;
	double *d_error_sum_arr;
	point_t *d_data;
	
  be = rms_error(bm, bc);

	//Allocate memory for d_dm
	error = cudaMalloc(&d_dm, (sizeof(double) * 8));
 	if(error){
   	fprintf(stderr, "cudaMalloc on d_dm returned %d %s\n", error,
    	cudaGetErrorString(error));
   	exit(1);
 	}
	
	//Allocate memory for d_dc
	error = cudaMalloc(&d_dc, (sizeof(double) * 8));
 	if(error){
   	fprintf(stderr, "cudaMalloc on d_dc returned %d %s\n", error,
  	  cudaGetErrorString(error));
   	exit(1);
 	}
	
	//Allocate memory for d_error_sum_arr
	error = cudaMalloc(&d_error_sum_arr, (sizeof(double) * 1000));
 	if(error){
   	fprintf(stderr, "cudaMalloc on d_error_sum_arr returned %d %s\n", error,
   	  cudaGetErrorString(error));
   	exit(1);
 	}

	//Allocate memory for d_data
	error = cudaMalloc(&d_data, sizeof(data));
 	if(error){
   	fprintf(stderr, "cudaMalloc on d_data returned %d %s\n", error,
   	  cudaGetErrorString(error));
   	exit(1);
 	}

  while(!minimum_found) {
    for(i=0;i<8;i++) {
      dm[i] = bm + (om[i] * step);
      dc[i] = bc + (oc[i] * step);    
    }

		//Copy memory for dm to d_dm
  	error = cudaMemcpy(d_dm, dm, (sizeof(double) * 8), cudaMemcpyHostToDevice);  
  	if(error){
    	fprintf(stderr, "cudaMemcpy to d_dm returned %d %s\n", error,
      cudaGetErrorString(error));
  	}

		//Copy memory for dc to d_dc
  	error = cudaMemcpy(d_dc, dc, (sizeof(double) * 8), cudaMemcpyHostToDevice);  
  	if(error){
    	fprintf(stderr, "cudaMemcpy to d_dc returned %d %s\n", error,
      cudaGetErrorString(error));
  	}

		//Copy memory for data to d_data
  	error = cudaMemcpy(d_data, data, sizeof(data), cudaMemcpyHostToDevice);  
  	if(error){
    	fprintf(stderr, "cudaMemcpy to d_data returned %d %s\n", error,
      cudaGetErrorString(error));
  	}
		
    for(i=0;i<8;i++) {
			//Host variable storing the array returned from the kernel function.
			double h_error_sum_arr[1000];
			
			//Stores the total sum of the values from the error sum array.
			double error_sum_total;

			//Stores the mean of the total sum of the error sums.
			double error_sum_mean;

			//Call the rms_error function using 100 blocks and 10 threads.
			d_rms_error <<<100,10>>>(&d_dm[i], &d_dc[i], d_error_sum_arr, d_data);
			cudaThreadSynchronize();

			//Copy memory for d_error_sum_arr
		  error = cudaMemcpy(&h_error_sum_arr, d_error_sum_arr, (sizeof(double) * 1000), cudaMemcpyDeviceToHost);  
		  if(error){
	    fprintf(stderr, "cudaMemcpy to error_sum returned %d %s\n", error,
	      cudaGetErrorString(error));
		  }

			//Loop through the error sum array returned from the kernel function
			for(int j=0; j<n_data; j++) {
				//Add each error sum to the error sum total.
    		error_sum_total += h_error_sum_arr[j];
  		}

			//Calculate the mean for the error sum.
			error_sum_mean = error_sum_total / n_data;

			//Calculate the square root for the error sum mean.
			e[i] = sqrt(error_sum_mean);

      if(e[i] < best_error) {
        best_error = e[i];
        best_error_i = i;
      }

			//Reset the error sum total.
			error_sum_total = 0;
    }

    //printf("best m,c is %lf,%lf with error %lf in direction %d\n", 
      //dm[best_error_i], dc[best_error_i], best_error, best_error_i);

    if(best_error < be) {
      be = best_error;
      bm = dm[best_error_i];
      bc = dc[best_error_i];
    } else {
      minimum_found = 1;
    }
  }

	//Free memory for d_dm
	error = cudaFree(d_dm);
	if(error){
		fprintf(stderr, "cudaFree on d_dm returned %d %s\n", error,
	  	cudaGetErrorString(error));
		exit(1);
	}
	
	//Free memory for d_dc
	error = cudaFree(d_dc);
	if(error){
		fprintf(stderr, "cudaFree on d_dc returned %d %s\n", error,
			cudaGetErrorString(error));
		exit(1);
	}

	//Free memory for d_data
	error = cudaFree(d_data);
	if(error){
		fprintf(stderr, "cudaFree on d_data returned %d %s\n", error,
	  	cudaGetErrorString(error));
	 	exit(1);
	}
		
	//Free memory for d_error_sum_arr
	error = cudaFree(d_error_sum_arr);
	if(error){
		fprintf(stderr, "cudaFree on d_error_sum_arr returned %d %s\n", error,
	  	cudaGetErrorString(error));
	 	exit(1);
	}

  printf("minimum m,c is %lf,%lf with error %lf\n", bm, bc, be);

	//Get the system time after we have run the linear regression function.
	clock_gettime(CLOCK_MONOTONIC, &finish);

	//Calculate the time spent between the start time and end time.
  time_difference(&start, &finish, &time_elapsed);

	//Output the time spent running the program.
  printf("Time elapsed was %lldns or %0.9lfs\n", time_elapsed, 
         (time_elapsed/1.0e9));
	
  return 0;
}
