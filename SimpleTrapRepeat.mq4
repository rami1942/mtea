//+------------------------------------------------------------------+
//|                                             SimpleTrapRepeat.mq4 |
//|                                                         rami1942 |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "rami1942"
#property link      ""

#include <stderror.mqh>
#include <stdlib.mqh>

#define WAIT_TIME 5
#define COMMENT "SimpleTrapRepeat"

//--- input parameters
extern double    lots=0.07;
extern int       slippage=1;
extern double    lowlimitRate = 0;
extern double    highlimitRate = 0;
extern bool      stopOnly = false;
extern bool      isBuy = false;
extern double    targetPips = 0.20;

double tgtPrices[] = { 82.25, 82.45, 82.65, 82.85, 83.05, 83.25, 83.45, -1};

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

/*
void doTrailing(int ticket, int trailPips) {
   if (OrderSelect(ticket, SELECT_BY_TICKET) == false) return;
      
   if (OrderType() == OP_SELL) {
      double trailPrice = trailPips / 100.0;
      double askPrice = Ask;
      if (OrderStopLoss() == 0 && (OrderOpenPrice() - askPrice > trailPrice * 2)) {
          OrderModify(ticket, OrderOpenPrice(), askPrice + trailPrice, OrderTakeProfit(), 0, Red);
          OrderPrint();
      } else if (OrderStopLoss() != 0 && (OrderStopLoss() - askPrice > trailPrice + 0.10)) {
          Print("Modify Ask=", askPrice); 
          OrderPrint();
          OrderModify(ticket, OrderOpenPrice(), askPrice + trailPrice, OrderTakeProfit(), 0, Red);
      }
   }
}
*/

// Run every tick.
void doEachTick() {
   int i = 0;
   while(true) {
      if (tgtPrices[i] == -1) break;
      int tgtMagic = 100000 + tgtPrices[i] * 100;
      if (!isPositionOrdered(tgtMagic)) {
         processOrder(tgtPrices[i], tgtMagic, targetPips, isBuy);
      }
      i++;
   }
}

void processOrder(double targetPrice, int magic, double targetPips, bool isBuy) {   
   int errCode;
   
   if (isBuy) {
      if (Ask <= targetPrice) {
         doOrderSend(OP_BUYSTOP, lots, targetPrice, slippage, lowlimitRate, targetPrice + targetPips, COMMENT, magic, errCode);
      } else {
         if (!stopOnly) {
            doOrderSend(OP_BUYLIMIT, lots, targetPrice, slippage, lowlimitRate, targetPrice + targetPips, COMMENT, magic, errCode);
         }
      }
   } else {
      if (Bid <= targetPrice) {
         if (!stopOnly) {
            doOrderSend(OP_SELLLIMIT, lots, targetPrice, slippage, highlimitRate, targetPrice - targetPips, COMMENT, magic, errCode);
         }
      } else {
         doOrderSend(OP_SELLSTOP, lots, targetPrice, slippage, highlimitRate, targetPrice - targetPips, COMMENT, magic, errCode);
      }
   }
}

// Is the position is ordered?
bool isPositionOrdered(int magic) {
   int ticket = getTicket(magic);   
   return (ticket != -1);
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