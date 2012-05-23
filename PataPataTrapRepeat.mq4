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
   double price = Ask;

   // トラップ本数カウント
   int i = 0;
   int n = 0;
   while(true) {
      if (tgtPrices[i] == -1) break;
      n++;
      i++;
   }

   // 現在価格に隣接しているトラップを選択してprocessTrapに投げる
   if (price > tgtPrices[0]) {
      // case 1    PRICE > price1 > price2 > ...
      Print("case 1");
      processTrap(tgtPrices[0], -1.0);

   } else if (price < tgtPrices[n - 1]) {
      // case 2    price1 > price2 > .. > priceN > PRICE
      Print ("case 2");
      processTrap(-1.0, tgtPrices[n - 1]);

   } else {
      // case 3    price1 > price2 > priceK > PRICE> priceL > ..
      for (i = 0; i < n; i++) {
          if (tgtPrices[i] > price && price > tgtPrices[i+1]) {
              Print("case 3");
              processTrap(tgtPrices[i], tgtPrices[i+1]);
              break;
          }
      }
   }
   
}

void processTrap(double trapPriceH, double trapPriceL) {
    // AskとBidがトラップを跨いでいる状態のときは処理をスキップ
    if (Ask > trapPriceH && trapPriceH > Bid) return;
    if (Ask > trapPriceL && trapPriceL > Bid) return;

    Print("Up trap: ", trapPriceH);
    Print("Dn trap: ", trapPriceL);

    if (trapPriceH > 0) {
        checkSetTrap(trapPriceH, true);
    }
    if (trapPriceL > 0) {
        checkSetTrap(trapPriceL, false);
    }
}

// トラップの状態をチェックし、必要であればトラップを仕掛ける
void checkSetTrap(double price, bool isBuy) {
    Print("Price = ", price, " isBuy=", isBuy);

    int magicBase = price * 1000.0;
    int ticketBuy = getTicket(magicBaseAsk + magicBase);
    int ticketSell= getTicket(magicBaseBid + magicBase);

    Print("ticketBuy =", ticketBuy, " ticketSell=", ticketSell);

    if (ticketBuy == -1 && ticketSell == -1) {
        // 注文が出てないので注文する
        int errCode;
        if (isBuy) {
            doOrderSend(OP_BUYSTOP, lots, price, slippage, lowlimitRate, price + 0.3, COMMENT, magicBaseAsk + magicBase, errCode);
        } else {
            doOrderSend(OP_SELLSTOP, lots, price, slippage, highlimitRate, price - 0.3, COMMENT, magicBaseAsk + magicBase, errCode);
        }
    } else {
        Price("Price = ", price, " has already ordered. Skip it.")
    }



}


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
