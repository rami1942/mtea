//+------------------------------------------------------------------+
//|                                                         Lock.mq4 |
//|                                                         rami1942 |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "rami1942"
#property link      ""

/*
 * trailBorder分の含み益が出たら、ストップをlockWidthに変更して利益を
 * 確定するEA
 */

#include <stderror.mqh>
#include <stdlib.mqh>

//--- input parameters
extern double    lockWidth=0.02;
extern double    trailBorder=0.2;

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init() {
   return(0);
}
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit() {
   return(0);
}

//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start() {
   if (IsTradeAllowed() == false) {
      Print("Trade is not Allowed.");
      return(0);
   }
   doEachTick();
   return(0);
}
//+------------------------------------------------------------------+

// Run every tick.
void doEachTick() {
   for (int i = 0; i < OrdersTotal(); i++) {
      if (!OrderSelect(i, SELECT_BY_POS)) continue;
      if (OrderSymbol() != Symbol()) continue;
 
      // magicno付きの注文は無視する
      if (OrderMagicNumber() > 0) continue;
 
      if (OrderType() == OP_BUY && OrderTakeProfit() > 150.0) {
         if (Bid > OrderOpenPrice() + trailBorder && OrderOpenPrice() + lockWidth > OrderStopLoss()) {
            OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice() + lockWidth, OrderTakeProfit(), 0, IndianRed);
         }
      } else if (OrderType() == OP_SELL && OrderTakeProfit() != 0 && OrderTakeProfit() < 50.0) {
         if (Ask < OrderOpenPrice() - trailBorder && OrderOpenPrice() - lockWidth < OrderStopLoss()) {
            OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice() - lockWidth, OrderTakeProfit(), 0, IndianRed);
         }
      }
   }
}