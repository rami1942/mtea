//+------------------------------------------------------------------+
//|                                                     AUD-CAD2.mq4 |
//|                                                         rami1942 |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "rami1942"
#property link      ""

#property indicator_separate_window
#property indicator_buffers 1
#property indicator_color1 Red
//--- buffers
double ExtMapBuffer1[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- indicators
   SetIndexStyle(0,DRAW_LINE);
   SetIndexBuffer(0,ExtMapBuffer1);
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
//----
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
  {
   int    counted_bars=IndicatorCounted();
   if(counted_bars>0) counted_bars--;

   int limit=Bars-counted_bars;
   
   for (int i = 0; i < limit; i++) {
      ExtMapBuffer1[i] = iClose("AUDJPYpro", 0, i) - iClose("CADJPYpro", 0, i);
   }
   return(0);
  }
//+------------------------------------------------------------------+