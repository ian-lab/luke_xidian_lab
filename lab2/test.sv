//Lab 1 - Task 3, Step 2
//
//Declare a program block with arguments to connect
//to modport TB declared in interface
//ToDo
`timescale 1ns/100ps
program automatic test(router_io.TB rtr_io);

  bit [3:0] sa; // source address
  bit [3:0] da; // destination address
  logic [7:0] payload[$];
  int run_for_n_packets;

  initial begin
    // $vcdpluson; 
    reset();
    run_for_n_packets = 21;
    repeat(run_for_n_packets) begin
      gen();
      send();      
    end
    repeat(10) @(rtr_io.cb);
  end

  task reset();
    rtr_io.reset_n = 1'b0;
    rtr_io.cb.frame_n <= '1;
    rtr_io.cb.valid_n <= '1;
    #2 rtr_io.cb.reset_n <= 1'b1;
    repeat(15) @(rtr_io.cb);
  endtask : reset

  task gen();
    sa = 3;
    da = 7;
    payload.delete();
    repeat($urandom_range(4,2))
      payload.push_back($urandom);
  endtask 

  task send();
    send_addrs();
    send_pad();
    send_payload();
    // repeat(10) @(rtr_io);
  endtask 

  // 发送地址
  task send_addrs();
    rtr_io.cb.frame_n[sa] <= 1'b0;
    for (int i = 0; i < 4; i++) begin
      rtr_io.cb.din[sa] <= da[i];
      @(rtr_io.cb);
    end
  endtask
  // 发送Pad
  task send_pad();
    rtr_io.cb.frame_n[sa] <= 1'b0;
    rtr_io.cb.valid_n[sa] <= 1'b1;
    rtr_io.cb.din[sa] <= 1'b1;
    repeat(5) @(rtr_io.cb);
  endtask 
  // 发送数据
  task send_payload();
    foreach(payload[index])begin
      $display(payload[index]);
      for (int i = 0; i < 8; i++) begin
        rtr_io.cb.din[sa] <= payload[index][i];
        rtr_io.cb.valid_n[sa] <= 1'b0;
        rtr_io.cb.frame_n[sa] <= ((i == 7) && (index == (payload.size() - 1 )));
        @(rtr_io.cb);
      end
    end
      

    rtr_io.cb.valid_n[sa] <= 1'b1;

  endtask


endprogram: test
