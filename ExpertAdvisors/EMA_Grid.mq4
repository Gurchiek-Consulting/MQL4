#property copyright   "Thomas Gurchiek 2020"
#property link        "http://www.mql4.com"
#property strict

//input bool TakeProfitOn = TRUE;
input double Lots          =0.1;
input double TrailingStop  =0.0001;
//input double StopLoss = 0.0800;
//input double GridSpace = 0.0010;
input double ATRPeriod = 14;
//double FastMA = 3;
double SlowMA = 200;
//double SlowerMA = 50;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//int TakeProfitOption()
//{
//   if(TakeProfitOn)
//   {
//      return TakeProfit;
//   }
//   else
//   {
//      return 0;
//   }
//}

void OnTick(void)
  {
   int    cnt,ticket,total;
   
//---
// initial data checks
// it is important to make sure that the expert works with a normal
// chart and the user did not make any mistakes setting external
// variables (Lots, StopLoss, TakeProfit,
// TrailingStop) in our case, we check TakeProfit
// on a chart of less than 100 bars
//---

//--- to simplify the coding and speed up access data are put into internal variables
// current chart, current period, 20 candles, no shift, exponential, close price)
   double SlowEMA = iMA(NULL,0,SlowMA,0,MODE_EMA,PRICE_CLOSE,0);
   //double LastSlowEMA = iMA(NULL,0,SlowMA,0,MODE_EMA,PRICE_CLOSE,1);
   //double FastEMA = iMA(NULL,0,FastMA,0,MODE_EMA,PRICE_CLOSE,0);
   //double LastFastEMA = iMA(NULL,0,FastMA,0,MODE_EMA,PRICE_CLOSE,1);

   //double SlowerEMA = iMA(NULL,0,SlowerMA,0,MODE_EMA,PRICE_CLOSE,0);

   //double CCIValue = iCCI(NULL,0,200,PRICE_CLOSE,0);

// Calculate Gridspacing based on ATR/2
   double GridSpace = NormalizeDouble(iATR(0,0,ATRPeriod,0)/2,4);
   
// Calculate TakeProfit based on ATR/2
   double TakeProfit = NormalizeDouble(iATR(0,0,ATRPeriod,0)/2,4);
   
// Calculate Risk Per Trade
   //double riskPerTrade = AccountBalance * 0.02;

// Buy order stop loss (Ask - (AccountBalance*StopLoss)
// Setting this manually for now
   //double LongSL = Ask - StopLoss;
   double LongSL = (Ask - GridSpace)- 0.002;
   
//Short order stop loss (Bid + (AccountBalance*StopLoss)
// Setting this manually for now
   //double ShortSL = Bid + StopLoss;
   double ShortSL = (Bid + GridSpace)+ 0.002;
   
 // Get current Ask price
   double AskPrice = MarketInfo(0,MODE_ASK);
 // Get current Bid price
   double BidPrice = MarketInfo(0,MODE_BID);

   //int tp = TakeProfitOption();

   total=OrdersTotal();
   if(total<1)
     {
      //--- no opened orders identified
      if(AccountFreeMargin()<(1000*Lots))
        {
         Print("We have no money. Free Margin = ",AccountFreeMargin());
         return;
        }
      //--- check for long position (BUY) possibility
      //if((LastFastEMA < LastSlowEMA) && (FastEMA > SlowEMA) && (FastEMA > SlowerEMA))
      //if((LastFastEMA < LastSlowEMA) && (FastEMA > SlowEMA))
      // While current price is above 200 EMA open grid. 10 pip grid 2 by 2.
      if(BidPrice && AskPrice > SlowEMA)
        {
         //ticket=OrderSend(Symbol(),OP_BUY,Lots,Ask,3,LongSL,Ask+TakeProfit*Point,"macd sample",16384,0,Green);
         ticket=OrderSend(Symbol(),OP_BUYLIMIT,Lots,Bid-GridSpace,3,LongSL,Ask+TakeProfit,"CCI Scalping EA",16384,0,Green);
         Sleep(10000);
         RefreshRates();
         ticket=OrderSend(Symbol(),OP_SELLLIMIT,Lots,Ask+GridSpace,3,ShortSL,Bid-TakeProfit,"CCI Scalping EA",16384,0,Red);
         if(ticket>1)
           {
            if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
               Print("BUY order opened : ",OrderOpenPrice());
           }
         else
            Print("Error opening BUY order : ",GetLastError());
         return;
        }
      //--- check for short position (SELL) possibility
      //if((LastFastEMA > LastSlowEMA) && (FastEMA < SlowEMA) && (FastEMA < SlowerEMA))// supposed to be SlowerEMA??
      //if((LastFastEMA > LastSlowEMA) && (FastEMA < SlowEMA))
      if(BidPrice && AskPrice < SlowEMA)
        {
         //ticket=OrderSend(Symbol(),OP_SELL,Lots,Bid,3,ShortSL,Bid-TakeProfit*Point,"macd sample",16384,0,Red);
         ticket=OrderSend(Symbol(),OP_BUYSTOP,Lots,Ask+GridSpace,3,LongSL,(Bid+GridSpace)+TakeProfit,"CCI Scalping EA",16384,0,Green);
         Sleep(10000);
         RefreshRates();
         ticket=OrderSend(Symbol(),OP_SELLSTOP,Lots,Bid-GridSpace,3,ShortSL,(Ask-GridSpace)-TakeProfit-0.0002,"CCI Scalping EA",16384,0,Red);
         if(ticket>1)
           {
            if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
               Print("SELL order opened : ",OrderOpenPrice());
           }
         else
            Print("Error opening SELL order : ",GetLastError());
        }
      //--- exit from the "no opened orders" block
      return;
     }
     
// Looking for pending orders once one of the orders is filled. OCO = One Cancels Other
   int i;
   int CountFilledOrders = 0;
   int CountPendingOrders = 0;

   // Count the number of pending and filled orders for this EA
   for (i = OrdersTotal() - 1; i >=0; i--) {
      if (OrderSelect(i, SELECT_BY_POS)) {
         if (OrderSymbol() == Symbol() && OrderMagicNumber() == 16384) {
            switch (OrderType()) {
               case OP_BUY:
               case OP_SELL:
                  CountFilledOrders++;
                  break;
               default:
                  CountPendingOrders++;
                  break;        
            }
         }
      }
   }
   
   // If there are both pending and filled orders, delete the pending orders 
   if (CountFilledOrders > 0 && CountPendingOrders > 0) {
      for (i = OrdersTotal() - 1; i >=0; i--) {
         if (OrderSelect(i, SELECT_BY_POS)) {
            if (OrderSymbol() == Symbol() && OrderMagicNumber() == 16384) {
               switch (OrderType()) {
                  case OP_BUY:
                  case OP_SELL:
                     break;
                  default:
                     OrderDelete(OrderTicket());
                     break;        
               }
            }
         }
      }
   }
     
     
//--- it is important to enter the market correctly, but it is more important to exit it correctly...
   for(cnt=0; cnt<total; cnt++)
     {
      if(!OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES))
         continue;
      if(OrderType()<=OP_SELL &&   // check for opened position
         OrderSymbol()==Symbol())  // check for symbol
        {
         //--- long position is opened
         if(OrderType()==OP_BUY)
           {
            //--- should it be closed?
            //if((LastFastEMA > LastSlowEMA) && (FastEMA < SlowEMA) && (FastEMA < SlowerEMA))
            //if((LastFastEMA > LastSlowEMA) && (FastEMA < SlowEMA))
              //{
               //--- close order and exit
              // if(!OrderClose(OrderTicket(),OrderLots(),Bid,3,Violet))
                //  Print("OrderClose error ",GetLastError());
              // return;
             // }
            //--- check for trailing stop
            if(TrailingStop>0)
              {
               if(Bid-OrderOpenPrice()>Point*TrailingStop)
                 {
                  if(OrderStopLoss()<Bid-Point*TrailingStop)
                    {
                     //--- modify order and exit
                     if(!OrderModify(OrderTicket(),OrderOpenPrice(),Bid-Point*TrailingStop,OrderTakeProfit(),0,Green))
                        Print("OrderModify error ",GetLastError());
                     return;
                    }
                 }
              }
           }
         else // go to short position
           {
            //--- should it be closed?
            //if((LastFastEMA < LastSlowEMA) && (FastEMA > SlowEMA) && (FastEMA > SlowerEMA))
            //if((LastFastEMA < LastSlowEMA) && (FastEMA > SlowEMA))
              //{
               //--- close order and exit
              // if(!OrderClose(OrderTicket(),OrderLots(),Ask,3,Violet))
              //    Print("OrderClose error ",GetLastError());
              // return;
              //}
            //--- check for trailing stop
            if(TrailingStop>0)
              {
               if((OrderOpenPrice()-Ask)>(Point*TrailingStop))
                 {
                  if((OrderStopLoss()>(Ask+Point*TrailingStop)) || (OrderStopLoss()==0))
                    {
                     //--- modify order and exit
                     if(!OrderModify(OrderTicket(),OrderOpenPrice(),Ask+Point*TrailingStop,OrderTakeProfit(),0,Red))
                        Print("OrderModify error ",GetLastError());
                     return;
                    }
                 }
              }
           }
        }
     } // End for loop
//---
  } // End OnTick()
//+------------------------------------------------------------------+

