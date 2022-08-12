# Update from 9.72 to 10.12    # Aug 2022

Protocol of api-changes:  https://www.interactivebrokers.com/en/index.php?f=24356

1. Update Incoming and outgoing Messages constants
   lib/ib/messages/incoming.rb
   lib/ib/massages/outgoing.rb 

   note: Field types :  int   = 1
                        string = 2
                        float = 2  
   python/message.py 

2. Update ServerVersion
   lib/ib/server_versions.rb
   New supported server Version: 165  /:min_server_er_historical_schedule/

   python/server_versions.py


3. Update ClientVersion
   is NOT necessary. According to EClient.java, ClientVersion 66 is the most recent one 

   ToDo: Can we omit the constant at all?

4. Update Max_Version --:  165 
   in lib/ib/server_versions.rb
       
5. Start of a console with a running papertrading account

> BUFFER:: "\x00\x00\x00\x1A165\x0020220812 06:42:26 GMT\x00"
> F: Connected to server, version: 165, using client-id: 2000,
>    connection time: 2022-08-12 06:42:27 +0000 local, 2022-08-12T06:42:26+00:00 remote.
> BUFFER:: "\x00\x00\x00B15\x001\x00DF4035274,DU4035275,DU4035276,DU4035277,DU4035278,DU4035279,\x00"
> F: Connected to server, version: 165, using client-id: 2000,
>    connection time: 2022-08-12 06:42:27 +0000 local, 2022-08-12T06:42:26+00:00 remote.                                                
> BUFFER:: "\x00\x00\x00B15\x001\x00DF4035274,DU4035275,DU4035276,DU4035277,DU4035278,DU4035279,\x00"                                   
> I: < ManagedAccounts: DF4035274 - DU4035275 - DU4035276 - DU4035277 - DU4035278 - DU4035279>                         
> BUFFER:: "\x00\x00\x00\x069\x001\x001\x00"                                                                                            
> I: Got next valid order id: 1.                                                                                                        
> Connection established on Port  4002, client_id 2000 used
 
**The login-procedure is unchanged!**

6. Starting with tests

6.1 connect_spec.rb 
   After editing connect.yml the test passes

6.2 ContractDetails
    Changes:  a) Version is not transmitted anymore
              b) contract_detail.md_size_multiplier is not used anymore 
              c) remaining buffer: (stock) => ["COMMON", "1", "1", "100"],
    --:: added stock_type, min_size, size_increment, suggested_size_increment 
    to lib/ib/model/ContractDetail.rb  and /lib/ib/messages/incoming/contract_data.rb
  
    Ensure that the buffer is read completely!

    

