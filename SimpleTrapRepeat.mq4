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
#define COMMENT "ConsTrapRepeat"

//--- input parameters
extern double    lots=0.01;
extern int       slippage=3;
extern double    lowlimitRate = 50.0;
extern double    highlimitRate = 87.7;
extern bool      isBuy = false;

int tgtMagics[] =    { 10799, 10796, 10793, 10790, 10787, 10784, 10781, 10778, 10775, 10772, 10769, 10766, 10763, 10760, 10757, 10754, 10751, -1};
double tgtPrices[] = {  79.9,  79.6,  79.3,  79.0,  78.7,  78.4,  78.1,  77.8,  77.5,  77.2,  76.9,  76.6,  76.3,  76.0,  75.7,  75.4,  75.1, -1};
int targetPips[] =   {    30,    30,    30,    30,    30,    30,    30,    30,    30,    30,    30,    30,    30,    30,    30,    30,    30, -1};

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
   int i = 0;
   while(true) {
      if (tgtMagics[i] == -1) break;
      processOrder(tgtPrices[i], tgtMagics[i], targetPips[i], isBuy);      
      i++;
   }
}

void processOrder(double targetPrice, int magic, int targetPips, bool isBuy) {
   if (isPositionOrdered(magic)) return;
   
   int errCode;
   int ticket;
   if (isBuy) {
      if (Ask <= targetPrice) {
         ticket = doOrderSend(OP_BUYSTOP, lots, targetPrice, slippage, lowlimitRate, targetPrice + targetPips / 100.0, COMMENT, magic, errCode);
      } else {
         ticket = doOrderSend(OP_BUYLIMIT, lots, targetPrice, slippage, lowlimitRate, targetPrice + targetPips / 100.0, COMMENT, magic, errCode);
      }
   } else {
      if (Bid <= targetPrice) {
         ticket = doOrderSend(OP_SELLLIMIT, lots, targetPrice, slippage, highlimitRate, targetPrice - targetPips / 100.0, COMMENT, magic, errCode);
      } else {
         ticket = doOrderSend(OP_SELLSTOP, lots, targetPrice, slippage, highlimitRate, targetPrice - targetPips / 100.0, COMMENT, magic, errCode);
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