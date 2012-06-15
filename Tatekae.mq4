//+------------------------------------------------------------------+
//|                                                      Tatekae.mq4 |
//|                                                         rami1942 |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "rami1942"
#property link      ""

#include <stderror.mqh>
#include <stdlib.mqh>

#define WAIT_TIME 5
#define COMMENT "Tatekae"

//--- input parameters
extern double    lots=0.03;
extern int       slippage=3;

color MarkColor[6] = {Red, Blue, Red, Blue, Red, Blue};

int poolMagics[];
int poolTickets[];

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
   initPool();
   doEachTick();
   return(0);
}
//+------------------------------------------------------------------+

// Run every tick.
void doEachTick() {
   int ticket;

   bool order984 = false;
   bool order987 = false;

   ticket = getTicket(10984);
   if (ticket != -1) {
      OrderSelect(ticket, SELECT_BY_TICKET);
      if (OrderType() == OP_SELL) {
         // ポジション持ってる
         order984 = true;

         if (Ask < OrderStopLoss() - 0.5) {
	    ModifyOrder(ticket, OrderOpenPrice(), OrderStopLoss() - 0.3, OrderTakeProfit(), 0, Yellow);
	 }
      }
   }

   ticket = getTicket(10987);
   if (ticket != -1) {
      OrderSelect(ticket, SELECT_BY_TICKET);
      if (OrderType() == OP_SELL) {
         // ポジション持ってる
         order987 = true;
         if (Ask < OrderStopLoss() - 0.5) {
	    ModifyOrder(ticket, OrderOpenPrice(), OrderStopLoss() - 0.3, OrderTakeProfit(), 0, Yellow);
	 }
      }
   } else {
      // オーダーも出ていない

      // 一つ下のオーダーが生きている
      if (order984) {
      }
   }


/*
   int i = 0;
   while(true) {
      if (tgtMagics[i] == -1) break;
      int ticket = getTicket(tgtMagics[i]);
      if (!OrderSelect(ticket, SELECT_BY_TICKET)) continue;

      if (OrderType() == OP_BUY || OrderType() == OP_SELL) {
      }

      i++;
   }
*/
}

void processOrder(double targetPrice, int magic, int targetPips, double limitPrice, double stopPrice, bool isBuy) {
   int errCode;
   
   if (isBuy) {
      if (Ask <= targetPrice) {
         doOrderSend(OP_BUYSTOP, lots, targetPrice, slippage, stopPrice, limitPrice, COMMENT, magic, errCode);
      } else {
         doOrderSend(OP_BUYLIMIT, lots, targetPrice, slippage, stopPrice, limitPrice, COMMENT, magic, errCode);
      }
   } else {
      if (Bid <= targetPrice) {
         doOrderSend(OP_SELLLIMIT, lots, targetPrice, slippage, stopPrice, limitPrice, COMMENT, magic, errCode);
      } else {
         doOrderSend(OP_SELLSTOP, lots, targetPrice, slippage, stopPrice, limitPrice, COMMENT, magic, errCode);
      }
   }
}

// Send a order.
//
// returns ticket no or -1 if failed.
int doOrderSend(int type, double lots, double openPrice, int slippage, double stoploss, double closePrice, string comment, int magic, int &errCode) {
   openPrice = NormalizeDouble(openPrice, Digits);
   stoploss = NormalizeDouble(stoploss, Digits);
   closePrice = NormalizeDouble(closePrice, Digits);

   int starttime = GetTickCount();

   while(true) {
      if(GetTickCount() - starttime > WAIT_TIME * 1000) {
         Print("OrderSend timeout. Check the experts log.");
         return(false);
      }

      if(IsTradeAllowed() == true) {
         RefreshRates();
         int ticket = OrderSend(Symbol(), type, lots, openPrice, slippage, stoploss, closePrice, comment, magic, 0, MarkColor[type]);
         if( ticket > 0) {
            return(ticket);
         }

         errCode = GetLastError();
         Print("[OrderSendError] : ", errCode, " ", ErrorDescription(errCode));
         Print("price=",openPrice,": stop=",stoploss,": close=",closePrice);
         if(errCode == ERR_INVALID_PRICE || errCode == ERR_INVALID_STOPS) {
            return(-1);
         }
      }
      Sleep(100);
   }
}

// Initialize poolMagics and poolTickets.
void initPool() {
   int n = 0;
   for (int i = 0; i < OrdersTotal(); i++) {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if (OrderSymbol() != Symbol()) continue;
      n++;
   }
   
   ArrayResize(poolMagics, n);
   ArrayResize(poolTickets, n);
   
   n = 0;
   for (i = 0; i < OrdersTotal(); i++) {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if (OrderSymbol() != Symbol()) continue;
      
      poolTickets[n] = OrderTicket();
      poolMagics[n] = OrderMagicNumber();
      
      n++;
   }
}

// Retrieve magic no to ticket no.
int getTicket(int magic) {
   for (int i = 0; i < ArraySize(poolMagics); i++) {
      if (poolMagics[i] == magic) return(poolTickets[i]);
   }
   return(-1);
}
