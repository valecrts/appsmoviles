import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        
        appBar: AppBar(

          backgroundColor: const Color(0xFFFFA843), 

        

          title: const Text('Banco Estado',
          style: TextStyle(color:Colors.white),),



          actions: [

             IconButton(icon: const Icon(Icons.search),
          color: Colors.white,
          onPressed: () {
            
          },),


            IconButton(icon: const Icon(Icons.notifications),
          color: Colors.white,
          onPressed: () {
            
          },),

            PopupMenuButton<String>( 
            icon: const Icon(Icons.menu,
             color:Colors.white,),
           
            
             itemBuilder:(BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'perfil',
                child: Row (children: [
                  Icon(Icons.account_circle),
                  SizedBox(width:10),
                  Text('Perfil'),
                
                ],
                ),

              ),

                const PopupMenuItem<String>(
                value: 'configuracion',
                child: Row (children: [
                  Icon(Icons.settings),
                  SizedBox(width: 10),
                  Text('Configuracion'),
                ],
                ),
                

              ),
            
              const PopupMenuItem<String>(
                value: 'miapp',
                child: Row (children: [
                  Icon(Icons.help_outline_rounded),
                  SizedBox(width: 10),
                  Text('Conoce tu app'),
                ],
                ),

              ),

           
          ],
          
          )
              
          
      

          ],
        ),
        
        body: SingleChildScrollView(
          child: Column(
            children: [

               Container(
                height: 180,
                width: double.infinity,
                margin: const EdgeInsets.only(left:16.0, right:16.0, bottom:12.0, top:12.0,),
                padding: const EdgeInsets.all(20.0),
                color: const Color.fromARGB(255, 0, 0, 0),

                child: const Center(
                  child: Text(
                    'Cuenta Rut',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ),
              ),

              SizedBox(height:2.0),


              Container(
                height: 160,
                width: double.infinity,
                margin: const EdgeInsets.only(left:16.0, right:16.0, bottom:12.0, top:12.0,),
                padding: const EdgeInsets.only(left:16.0, right:16.0, bottom:12.0, top:12.0,),
                color: const Color.fromARGB(255, 114, 114, 114),

                child: const Center(
                  child: Text(
                    'Tu tarjeta con beneficios',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ),
              ),

               SizedBox(height: 24.0),

              Container(
                height: 140,
                width: double.infinity,
                margin: const EdgeInsets.all(16.0),
                padding: const EdgeInsets.all(20.0),
                color: const Color.fromARGB(255, 204, 169, 53),


               child:Container(
                color: const Color.fromARGB(255, 204, 169, 53),

                child: const Center(
                  child: Text(
                    'Tus tarjetas',
                    style: TextStyle(
                      color: Color.fromARGB(255, 21, 21, 21),
                      fontSize: 24,
                    ),
                  ),
                ),
               )
              ),

              SizedBox(height: 24.0),

              Container(
                height: 160,
                width: double.infinity,
                margin: const EdgeInsets.only(left:16.0, right:16.0, bottom:12.0, top:12.0,),
                padding: const EdgeInsets.only(left:16.0, right:16.0, bottom:12.0, top:12.0,),
                color: const Color.fromARGB(255, 167, 140, 21),

                child: const Center(
                  child: Text(
                    'Tus ahorros',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ),
              ),

               SizedBox(height: 24.0),

              Container(
                height: 160,
                width: double.infinity,
                margin: const EdgeInsets.all(16.0),
                color: Colors.white,

                child:Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Container(
                      color: Colors.blue,

                      child: const Center (
                        child: Text('Aporta a TechoChile', 
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        ),
                      ),
                    ),
                    ),

                    SizedBox(width: 8.0,),

                    Expanded(child: Container (
                      color:Colors.red,
                       child: const Center (
                        child: Text('Cruz roja', 
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        ),
                      ),

                    ),
                    ),

                    SizedBox(width: 8.0,),
                    
                    Expanded(child: Container (
                      color:Colors.blueGrey,
                       child: const Center (
                        child: Text('Ahorra', 
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        ),
                      ),

                    ),
                    ),
                     SizedBox(width: 8.0,),

                     Expanded(child: Container (
                      color:Colors.green,
                       child: const Center (
                        child: Text('Servicios', 
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        ),
                      ),

                    ),
                    ),
                  ],
                )

                
              ),



            ],



          ),
        ),
       
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          selectedItemColor: const Color(0xFFFFA843), 


          items: const [

            BottomNavigationBarItem(icon:Icon(Icons.home_outlined),
            label: 'Inicio',),

            BottomNavigationBarItem(icon:Icon(Icons.swap_horiz),
            label: 'Transferir',),

            BottomNavigationBarItem(icon:Icon(Icons.lock_outlined),
            label: 'Seguridad',),

            BottomNavigationBarItem(icon:Icon(Icons.apps),
            label: 'Más',),


          ] ),
        


        
        ),
    );
  }
}
