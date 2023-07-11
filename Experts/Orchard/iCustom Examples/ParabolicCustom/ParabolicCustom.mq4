//+------------------------------------------------------------------+
//|                                              ParabolicCustom.mq4 |
//|                               Copyright 2012-2020, Orchard Forex |
//|                                     https://www.orchardforex.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012-2020, Orchard Forex"
#property link "https://www.orchardforex.com"
#property version "1.00"

input double InpStep         = 0.02; //	Step
input double InpMaximum      = 0.2;  //	Maximum

input double InpOrderSize    = 0.01;     //	Order size
input string InpTradeComment = __FILE__; //	Trade comment
input int    InpMagicNumber  = 2000001;  //	Magic number

double       TakeProfit; //	After conversion from points
double       StopLoss;

//
//	Identify the buffer numbers
//
const string IndicatorName = "Parabolic";
const int    BufferSAR     = 0;

int          OnInit() { return ( INIT_SUCCEEDED ); }

void         OnDeinit( const int reason ) {

   TakeProfit = 0;
   StopLoss   = 0;
}

void OnTick() {

   //
   //	Where this is to only run once per bar
   //
   if ( !NewBar() ) return;

   //
   //	Perform any calculations and analysis here
   //
   static double lastSAR       = 0;
   static double lastClose     = 0;
   double        currentSAR    = iCustom( Symbol(), Period(), IndicatorName, InpStep, InpMaximum, BufferSAR, 1 );
   double        close         = iClose( Symbol(), Period(), 1 );

   //
   //	Execute the strategy here
   //
   bool          buyCondition  = ( lastSAR != 0 ) && ( lastSAR > lastClose ) && ( currentSAR < close );
   bool          sellCondition = ( lastSAR != 0 ) && ( lastSAR < lastClose ) && ( currentSAR > close );

   if ( buyCondition ) {
      CloseAll( ORDER_TYPE_SELL );
      OrderOpen( ORDER_TYPE_BUY, StopLoss, TakeProfit );
   }
   else if ( sellCondition ) {
      CloseAll( ORDER_TYPE_BUY );
      OrderOpen( ORDER_TYPE_SELL, StopLoss, TakeProfit );
   }

   //
   //	Save any information for next time
   //
   lastSAR   = currentSAR;
   lastClose = close;

   return;
}

bool NewBar() {

   static datetime prevTime    = 0;
   datetime        currentTime = iTime( Symbol(), Period(), 0 );
   if ( currentTime != prevTime ) {
      prevTime = currentTime;
      return ( true );
   }
   return ( false );
}

void CloseAll( ENUM_ORDER_TYPE orderType ) {

   int cnt = OrdersTotal();
   for ( int i = cnt - 1; i >= 0; i-- ) {
      if ( OrderSelect( i, SELECT_BY_POS, MODE_TRADES ) ) {
         if ( OrderSymbol() == Symbol() && OrderMagicNumber() == InpMagicNumber && OrderType() == orderType ) {
            OrderClose( OrderTicket(), OrderLots(), OrderClosePrice(), 0 );
         }
      }
   }
}

bool OrderOpen( ENUM_ORDER_TYPE orderType, double stopLoss, double takeProfit ) {

   int    ticket;
   double openPrice;
   double stopLossPrice;
   double takeProfitPrice;

   if ( orderType == ORDER_TYPE_BUY ) {
      openPrice       = SymbolInfoDouble( Symbol(), SYMBOL_ASK );
      stopLossPrice   = openPrice - stopLoss;
      takeProfitPrice = openPrice + takeProfit;
   }
   else if ( orderType == ORDER_TYPE_SELL ) {
      openPrice       = SymbolInfoDouble( Symbol(), SYMBOL_BID );
      stopLossPrice   = openPrice + stopLoss;
      takeProfitPrice = openPrice - takeProfit;
   }
   else {
      return ( false );
   }

   ticket = OrderSend( Symbol(), orderType, InpOrderSize, openPrice, 0, stopLossPrice, takeProfitPrice, InpTradeComment, InpMagicNumber );

   return ( ticket > 0 );
}
