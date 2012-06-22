//+------------------------------------------------------------------+
//|                                       ConservativeTrapRepeat.mq4 |
//|                                                         rami1942 |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "rami1942"
#property link      ""

#include <stderror.mqh>
#include <stdlib.mqh>

#define WAIT_TIME 5
#define COMMENT "Martin"

//--- input parameters
extern double    lots=0.02;
extern double    profit=0.10;
extern int       slippage=3;

color MarkColor[6] = {DarkViolet, DarkViolet, DarkViolet, DarkViolet, DarkViolet, DarkViolet};

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
   int ticket1 = getTicket(301);
   int ticket2 = getTicket(302);
   int ticket3 = getTicket(303);
   int ticket4 = getTicket(304);

   if (ticket1 == -1) {
      // Cleanup orders.
      if (ticket2 != -1) OrderDelete(ticket2, Blue);
      if (ticket3 != -1) OrderDelete(ticket3, Blue);
      if (ticket4 != -1) OrderDelete(ticket4, Blue);

      // Start new martin.
      int errCode;
      double bidPrice = Bid;
      ticket1 = doOrderSend(OP_SELL, lots, bidPrice, slippage, 0, 0, "Martin Base", 301, errCode);
      OrderSelect(ticket1, SELECT_BY_TICKET);
      OrderModify(ticket1, OrderOpenPrice(), 0, bidPrice - profit, 0, Orange);
      processOrder(bidPrice + profit  , lots    , 302, profit*100);
      processOrder(bidPrice + profit*2, lots * 2, 303, profit*100);
      processOrder(bidPrice + profit*3, lots * 4, 304, profit*100);
   }
}

void processOrder(double targetPrice, double lots, int magic, int targetPips) {   
   int errCode;
   
   if (Bid <= targetPrice) {
      doOrderSend(OP_SELLLIMIT, lots, targetPrice, slippage, 0, targetPrice - targetPips / 100.0, COMMENT, magic, errCode);
   } else {
      doOrderSend(OP_SELLSTOP, lots, targetPrice, slippage, 0, targetPrice - targetPips / 100.0, COMMENT, magic, errCode);
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