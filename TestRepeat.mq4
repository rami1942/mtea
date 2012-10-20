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
extern int       slippage=1;
extern double    lowlimitRate = 0;
extern double    highlimitRate = 0;
extern bool      stopOnly = false;
extern bool      isBuy = false;

// AUDJPY 0.1 - 0.1
extern double    lots=0.01;
extern double    targetPips = 0.1;
double tgtPrices[] = {77, 77.1, 77.2, 77.3, 77.4, 77.5, 77.6, 77.7, 77.8, 77.9, 78, 78.1, 78.2, 78.3, 78.4, 78.5, 78.6, 78.7, 78.8, 78.9, 79, 79.1, 79.2, 79.3, 79.4, 79.5, 79.6, 79.7, 79.8, 79.9, 80, 80.1, 80.2, 80.3, 80.4, 80.5, 80.6, 80.7, 80.8, 80.9, 81, 81.1, 81.2, 81.3, 81.4, 81.5, 81.6, 81.7, 81.8, 81.9, 82, 82.1, 82.2, 82.3, 82.4, 82.5, 82.6, 82.7, 82.8, 82.9, 83, 83.1, 83.2, 83.3, 83.4, 83.5, 83.6, 83.7, 83.8, 83.9, 84, -1};

// 0.1 - 0.15
//extern double    lots=0.01;
//extern double    targetPips = 0.15;
//double tgtPrices[] = {77, 77.1, 77.2, 77.3, 77.4, 77.5, 77.6, 77.7, 77.8, 77.9, 78, 78.1, 78.2, 78.3, 78.4, 78.5, 78.6, 78.7, 78.8, 78.9, 79, 79.1, 79.2, 79.3, 79.4, 79.5, 79.6, 79.7, 79.8, 79.9, 80, 80.1, 80.2, 80.3, 80.4, 80.5, 80.6, 80.7, 80.8, 80.9, 81, 81.1, 81.2, 81.3, 81.4, 81.5, 81.6, 81.7, 81.8, 81.9, 82, 82.1, 82.2, 82.3, 82.4, 82.5, 82.6, 82.7, 82.8, 82.9, 83, 83.1, 83.2, 83.3, 83.4, 83.5, 83.6, 83.7, 83.8, 83.9, 84, -1};

// 0.15 - 0.15
//extern double    lots=0.01;
//extern double    targetPips = 0.15;
//double tgtPrices[] = {77, 77.15, 77.3, 77.45, 77.6, 77.75, 77.9, 78.05, 78.2, 78.35, 78.5, 78.65, 78.8, 78.95, 79.1, 79.25, 79.4, 79.55, 79.7, 79.85, 80, 80.15, 80.3, 80.45, 80.6, 80.75, 80.9, 81.05, 81.2, 81.35, 81.5, 81.65, 81.8, 81.95, 82.1, 82.25, 82.4, 82.55, 82.7, 82.85, 83, 83.15, 83.3, 83.45, 83.6, 83.75, 83.9, 84.05, -1};

// 0.15 - 0.20
//extern double    lots=0.01;
//extern double    targetPips = 0.20;
//double tgtPrices[] = {77, 77.15, 77.3, 77.45, 77.6, 77.75, 77.9, 78.05, 78.2, 78.35, 78.5, 78.65, 78.8, 78.95, 79.1, 79.25, 79.4, 79.55, 79.7, 79.85, 80, 80.15, 80.3, 80.45, 80.6, 80.75, 80.9, 81.05, 81.2, 81.35, 81.5, 81.65, 81.8, 81.95, 82.1, 82.25, 82.4, 82.55, 82.7, 82.85, 83, 83.15, 83.3, 83.45, 83.6, 83.75, 83.9, 84.05, -1};

// 0.20 - 0.20
//extern double    lots=0.01;
//extern double    targetPips = 0.20;
//double tgtPrices[] = {77, 77.2, 77.4, 77.6, 77.8, 78, 78.2, 78.4, 78.6, 78.8, 79, 79.2, 79.4, 79.6, 79.8, 80, 80.2, 80.4, 80.6, 80.8, 81, 81.2, 81.4, 81.6, 81.8, 82, 82.2, 82.4, 82.6, 82.8, 83, 83.2, 83.4, 83.6, 83.8, 84, -1};

// 0.20 - 0.25
//extern double    lots=0.01;
//extern double    targetPips = 0.25;
//double tgtPrices[] = {77, 77.2, 77.4, 77.6, 77.8, 78, 78.2, 78.4, 78.6, 78.8, 79, 79.2, 79.4, 79.6, 79.8, 80, 80.2, 80.4, 80.6, 80.8, 81, 81.2, 81.4, 81.6, 81.8, 82, 82.2, 82.4, 82.6, 82.8, 83, 83.2, 83.4, 83.6, 83.8, 84, -1};

// 0.20 - 0.30
//extern double    lots=0.01;
//extern double    targetPips = 0.3;
//double tgtPrices[] = {77, 77.2, 77.4, 77.6, 77.8, 78, 78.2, 78.4, 78.6, 78.8, 79, 79.2, 79.4, 79.6, 79.8, 80, 80.2, 80.4, 80.6, 80.8, 81, 81.2, 81.4, 81.6, 81.8, 82, 82.2, 82.4, 82.6, 82.8, 83, 83.2, 83.4, 83.6, 83.8, 84, -1};

// 0.25 - 0.25
//extern double    lots=0.01;
//extern double    targetPips = 0.25;
//double tgtPrices[] = {77, 77.25, 77.5, 77.75, 78, 78.25, 78.5, 78.75, 79, 79.25, 79.5, 79.75, 80, 80.25, 80.5, 80.75, 81, 81.25, 81.5, 81.75, 82, 82.25, 82.5, 82.75, 83, 83.25, 83.5, 83.75, 84, -1};

// 0.25 - 0.30
//extern double    lots=0.01;
//extern double    targetPips = 0.3;
//double tgtPrices[] = {77, 77.25, 77.5, 77.75, 78, 78.25, 78.5, 78.75, 79, 79.25, 79.5, 79.75, 80, 80.25, 80.5, 80.75, 81, 81.25, 81.5, 81.75, 82, 82.25, 82.5, 82.75, 83, 83.25, 83.5, 83.75, 84, -1};

// 0.25 - 0.35
//extern double    lots=0.01;
//extern double    targetPips = 0.35;
//double tgtPrices[] = {77, 77.25, 77.5, 77.75, 78, 78.25, 78.5, 78.75, 79, 79.25, 79.5, 79.75, 80, 80.25, 80.5, 80.75, 81, 81.25, 81.5, 81.75, 82, 82.25, 82.5, 82.75, 83, 83.25, 83.5, 83.75, 84, -1};

// 0.30 - 0.30
//extern double    lots=0.01;
//extern double    targetPips = 0.30;
//double tgtPrices[] = {77, 77.3, 77.6, 77.9, 78.2, 78.5, 78.8, 79.1, 79.4, 79.7, 80, 80.3, 80.6, 80.9, 81.2, 81.5, 81.8, 82.1, 82.4, 82.7, 83, 83.3, 83.6, 83.9, 84.2, -1};

// 0.30 - 0.35
//extern double    lots=0.01;
//extern double    targetPips = 0.35;
//double tgtPrices[] = {77, 77.3, 77.6, 77.9, 78.2, 78.5, 78.8, 79.1, 79.4, 79.7, 80, 80.3, 80.6, 80.9, 81.2, 81.5, 81.8, 82.1, 82.4, 82.7, 83, 83.3, 83.6, 83.9, 84.2, -1};

// 0.30 - 0.40
//extern double    lots=0.01;
//extern double    targetPips = 0.40;
//double tgtPrices[] = {77, 77.3, 77.6, 77.9, 78.2, 78.5, 78.8, 79.1, 79.4, 79.7, 80, 80.3, 80.6, 80.9, 81.2, 81.5, 81.8, 82.1, 82.4, 82.7, 83, 83.3, 83.6, 83.9, 84.2, -1};


// 0.40 - 0.40
//extern double    lots=0.01;
//extern double    targetPips = 0.40;
//double tgtPrices[] = {77, 77.4, 77.8, 78.2, 78.6, 79, 79.4, 79.8, 80.2, 80.6, 81, 81.4, 81.8, 82.2, 82.6, 83, 83.4, 83.8, 84.2, -1};

// 0.40 - 0.45
//extern double    lots=0.01;
//extern double    targetPips = 0.45;
//double tgtPrices[] = {77, 77.4, 77.8, 78.2, 78.6, 79, 79.4, 79.8, 80.2, 80.6, 81, 81.4, 81.8, 82.2, 82.6, 83, 83.4, 83.8, 84.2, -1};

// 0.40 - 0.50
//extern double    lots=0.01;
//extern double    targetPips = 0.50;
//double tgtPrices[] = {77, 77.4, 77.8, 78.2, 78.6, 79, 79.4, 79.8, 80.2, 80.6, 81, 81.4, 81.8, 82.2, 82.6, 83, 83.4, 83.8, 84.2, -1};

// 0.50 - 0.50
//extern double    lots=0.01;
//extern double    targetPips = 0.50;
//double tgtPrices[] = {77, 77.5, 78, 78.5, 79, 79.5, 80, 80.5, 81, 81.5, 82, 82.5, 83, 83.5, 84, -1};


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
         processOrder(tgtPrices[i], tgtMagic, targetPips, false);
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