#property indicator_separate_window
#property indicator_buffers 1

#property indicator_color1 White

double mapBuffer[];

int init() {
   SetIndexStyle(0, DRAW_LINE);
   SetIndexBuffer(0, mapBuffer);

   return(0);
}

int start() {
   int counted = IndicatorCounted();

   int i = Bars - counted - 1;
   while (i >= 0) {
      mapBuffer[i] = iClose("AUDJPY", 0, i) - iClose("CADJPY", 0, i);
      i--;
   }
}
