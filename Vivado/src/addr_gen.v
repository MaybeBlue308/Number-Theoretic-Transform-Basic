// address generator for both NTT and INTT                                            
// Sel: 0 for NTT/ 1 for INTT                                                         
// input: clk, rst, i_start, Sel (0 for NTT/ 1 for INTT)                              
// output: addr_up, addr_dn                                                           
module addrgen (                                                                      
  input  wire       clk,                                                              
  input  wire       rst,                                                              
  input  wire       i_start,                                          
  input  wire       Sel,          // 0: NTT, 1: INTT                                                                                       
  output wire [7:0] addr_up,                                          
  output wire [7:0] addr_dn,                                          
  output wire [6:0] zeta_idx,                                         
  output wire       done,                                             
  output wire       last_stage,                                       
  output wire       active                                            
);                                                                                                                                   
                                      
  wire rst_ntt   = rst |  Sel;                                        
  wire rst_intt  = rst | ~Sel;                                        
  wire go_ntt    = i_start & ~Sel;                                    
  wire go_intt   = i_start &  Sel;                                    
                                                                      
  // NTT instance                                                     
  wire [7:0] ntt_up, ntt_dn;                                          
  wire [6:0] ntt_zeta;                                                
  wire       ntt_done, ntt_last, ntt_active;                          
                                                                      
  ntt_addrgen256 u_ntt (                                              
    .clk(clk),                                                        
    .rst(rst_ntt),                                                    
    .i_start(go_ntt),                                                 
    .o_addr_up(ntt_up),                                               
    .o_addr_dn(ntt_dn),                                               
    .o_zeta_idx(ntt_zeta),                                            
    .o_done(ntt_done),                                                
    .o_last_stage(ntt_last),                                          
    .o_ntt_active(ntt_active)                                         
  );                                                                  
                                                                      
  // INTT instance                                                    
  wire [7:0] intt_up, intt_dn;                                        
  wire [6:0] intt_zeta;                                               
  wire       intt_done, intt_last, intt_active;                       
                                                                      
  intt_addrgen u_intt (                                               
    .clk(clk),                                                        
    .rst(rst_intt),                                                   
    .i_start(go_intt),                                                
    .o_addr_up(intt_up),                                              
    .o_addr_dn(intt_dn),                                              
    .o_zeta_idx(intt_zeta),                                           
    .o_done(intt_done),                                               
    .o_last_stage(intt_last),                                         
    .o_intt_active(intt_active)                                       
  );                                                                                                                                       
                                                                      
    assign addr_up = (Sel == 1'b0) ? ntt_up : intt_up;                
    assign addr_dn = (Sel == 1'b0) ? ntt_dn : intt_dn;                                                                         
    assign zeta_idx  = (Sel == 1'b0) ? ntt_zeta  : intt_zeta;         
    assign done      = (Sel == 1'b0) ? ntt_done  : intt_done;         
    assign last_stage= (Sel == 1'b0) ? ntt_last  : intt_last;         
    assign active    = (Sel == 1'b0) ? ntt_active: intt_active;       
                                                                      
endmodule                                                             
                                                                      
                                                                      
