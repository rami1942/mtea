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

double tgtPrices[] = {  81.4,  81.1,  80.8,  80.5,  80.2,  79.9,  79.6,  79.3,  79.0,  78.7,  78.4,  78.1,  77.8,  77.5,  77.2,  76.9,  76.6, -1};
int targetPips[] =   {    30,    30,    30,    30,    30,    30,    30,    30,    30,    30,    30,    30,    30,    30,    30,    30,    30, -1};

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
   doEachTick2();
}

void doEachTick2() {
   double price = Ask;
   // �g���b�v���̃J�E���g
   int i = 0;
   int n = 0;
   while(true) {
      if (tgtPrices[i] == -1) break;
      n++;
      i++;
   }

   if (price > tgtPrices[0]) {
      // case 1    PRICE > price1 > price2 > ...
      processTrap(tgtPrices[0], -1.0, targetPips[0], 0);

   } else if (price < tgtPrices[n - 1]) {
      // case 2    price1 > price2 > .. > priceN > PRICE
      processTrap(-1.0, tgtPrices[n - 1], 0, targetPips[n-1]);

   } else {
      // case 3    price1 > price2 > priceK > PRICE> priceL > ..
      for (i = 0; i < n; i++) {
          if (tgtPrices[i] > price && price > tgtPrices[i+1]) {
              processTrap(tgtPrices[i], tgtPrices[i+1], targetPips[i], targetPips[i+1]);
              break;
          }
      }
   }
   
}

void processTrap(double trapPriceH, double trapPriceL, int targetPipsH, int targetPipsL) {
    if (trapPriceH > 0 && !(Ask > trapPriceH && trapPriceH > Bid)) {
        setSingleTrap(trapPriceH, true, targetPipsH);
    }
    if (trapPriceL > 0 && !(Ask > trapPriceL && trapPriceL > Bid)) {
        setSingleTrap(trapPriceL, false, targetPipsL);
    }
}

// �g���b�v1�{�d�|����
void setSingleTrap(double price, bool isBuy, int targetPips) {
   int magicBase = price * 1000.0;
   int ticketBuy = getTicket(magicBaseAsk + magicBase);
   int ticketSell= getTicket(magicBaseBid + magicBase);

   // �����_�ł́A�����Ă͂��Ȃ�
   if (ticketBuy == -1 && ticketSell == -1) {
      int errCode;
      if (isBuy) {
         doOrderSend(OP_BUYSTOP, lots, price, slippage, lowlimitRate, price + targetPips/100.0, COMMENT, magicBaseAsk + magicBase, errCode);
      } else {
         doOrderSend(OP_SELLSTOP, lots, price, slippage, highlimitRate, price - targetPips/100.0, COMMENT, magicBaseAsk + magicBase, errCode);
      }
   } else {
//        Print("Price = ", price, " has already ordered. Skip it.");
   }
}


bool getTrendBuy() {
   return (true);
}

// ��������
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

// �v�[���̏�����
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

// �v�[�����������Ďw�肵��magic����`�P�b�g�ԍ����擾����
int getTicket(int magic) {
   for (int i = 0; i < ArraySize(poolMagics); i++) {
      if (poolMagics[i] == magic) return(poolTickets[i]);
   }
   return(-1);
}