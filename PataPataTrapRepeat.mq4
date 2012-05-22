//+------------------------------------------------------------------+
//|                                           PatapataTrapRepeat.mq4 |
//|                                                         rami1942 |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "rami1942"
#property link      ""

#include <stderror.mqh>
#include <stdlib.mqh>

#define WAIT_TIME 5
#define COMMENT "PatapataTrapRepeat"

//--- input parameters
extern double    lots=0.01;
extern int       slippage=3;
extern double    lowlimitRate = 50.0;
extern double    highlimitRate = 87.7;
extern bool      enableDoublePosition = false;

double tgtPrices[] = { 98.5, 97.5, -1};
int targetPips[] =   {   30,   30, -1};
bool isBuys[] =      { true, true, -1};

color MarkColor[6] = {Red, Blue, Red, Blue, Red, Blue};
int magicBaseAsk = 100000;
int magicBaseBid = 200000;

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
   int n = 0;
   while(true) {
      if (tgtPrices[i] == -1) break;
      n++;
      i++;
   }

   if (Ask > tgtPrices[0]) {
      // case 1    Ask > price1 > price2 > ...
      Print("case 1");
   } else if (Ask < tgtPrices[n - 1]) {
      // case 2    price1 > price2 > .. > priceN > Ask
      Print ("case 2");
   } else {
      // case 3    price1 > price2 > priceK > Ask > priceL > ..
   }
   
//   findLongTrap();
//   findShortTrap();
}

/*
void findLongTrap() {
    double price = Ask;
    int i = 0;
    int n = 0;
    while(true) {
        if (tgtPrices[i] == -1) break; 
        i++;
    }

    if (price < tgtPrices[0]) {
        processTrap(tgtPrices[0], true);
    } else if (price > tgtPrices[n-1]) {
        // NOP
    } else {
        for (i = 0; i < n - 1; i++) {
            if (tgtPrices[i] <= price && price <= tgtPrices[i+1]) {
                processTrap(tgtPrices[i+1], true);
		          break;
            }
        }
    }
}
*/


/*
void processTrap(double price, bool isBuy) {
    int magicBase = price * 100.0;
    int ticketAsk = getTicket(magicBaseAsk + magicBase);
    int ticketBid = getTicket(magicBaseBid + magicBase);
    if (ticketAsk == -1 && ticketBid == -1) {
      // There is no position.
      int errCode;
      if (isBuy) {
         doOrderSend(OP_BUYSTOP, lots, price, slippage, lowlimitRate, price + 0.3, COMMENT, magicBaseAsk + magicBase, errCode);
      } else {
         doOrderSend(OP_SELLSTOP, lots, price, slippage, highlimitRate, price - 0.3, COMMENT, magicBaseAsk + magicBase, errCode);
      }
    } else {
      // NOP
    }
}
*/

/*
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
*/

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