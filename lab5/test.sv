`timescale 1ns/100ps

program automatic test(router_io.TB rtr_io);
  `include "Packet.sv"
  int run_for_n_packets;
  bit [3:0] sa; // source address
  bit [3:0] da; // destination address
  logic [7:0] payload[$];
  logic [7:0] pkt2cmp_payload[$];

  Packet pkt2cmp = new();
  Packet pkt2send = new();

  initial begin
    // $vcdpluson; 
    run_for_n_packets = 10;
    reset();
    repeat(run_for_n_packets) begin
      gen();
      fork
        send();
        recv();
      join
      check();  
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
    static int pkts_generated = 0;
    pkt2send.name = $sformatf("Packet[%0d]", pkts_generated++);//0代表的是清除所有格式化输出的前面的0
    if (!pkt2send.randomize()) begin
      $display("\n%m\n [ERROR] %t: Randomize Error!!!", $realtime);
      $finish;
    end

    sa = pkt2send.sa;
    da = pkt2send.da;
    payload = pkt2send.payload;
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
    rtr_io.cb.din[sa] <= 1'b1;
    rtr_io.cb.valid_n[sa] <= 1'b1;
    repeat(5) @(rtr_io.cb);
  endtask 

  // 发送数据
  task send_payload();
    foreach(payload[index])
      for (int i = 0; i < 8; i++) begin
        rtr_io.cb.din[sa] <= payload[index][i];
        rtr_io.cb.valid_n[sa] <= 1'b0;
        rtr_io.cb.frame_n[sa] <= ((i == 7) && (index == (payload.size() - 1 )));
        @(rtr_io.cb);
      end
    rtr_io.cb.valid_n[sa] <= 1'b1;
  endtask

  task recv();
    static int pkt_cnt = 0;
    get_payload();
    pkt2cmp.da = da;
    pkt2cmp.payload = pkt2cmp_payload;
    pkt2cmp.name = $sformatf("rcvdPkt[%0d]", pkt_cnt++);
  endtask

  task get_payload();
    pkt2cmp_payload.delete();

    fork
      begin: wd_timer_fork
        fork: frameo_wd_timer
          @(negedge rtr_io.cb.frameo_n[da]);
          begin
            repeat(1000) @(rtr_io.cb);
            $display("\n%m\n[ERROR]%t Frame signal timed out!\n", $realtime);
            $finish;
          end
        join_any: frameo_wd_timer // fork-join_any会等待至少一个进程完成，然后再执行后继的语句。
        disable fork;
      end: wd_timer_fork
    join

    forever begin
      logic [7:0] datum;
      for (int i = 0; i < 8; i=i) begin
        if (!rtr_io.cb.valido_n[da]) 
          datum[i++] = rtr_io.cb.dout[da];
        if (rtr_io.cb.frameo_n[da]) 
          if (i==8) begin
            pkt2cmp_payload.push_back(datum);
            return;
          end
          else begin
            $display("\n%m\n[ERROR]%t Frame signal timed out!\n", $realtime);
            $finish;            
          end
          @(rtr_io.cb);
      end
      pkt2cmp_payload.push_back(datum);
    end
  endtask //get_payload

  task check ();
    string message;
    static int pkts_checked = 0;

    if (!pkt2send.compare(pkt2cmp, message)) begin
      $display("\n%m\n[ERROR]%t Packet #%0d %s\n", $realtime, pkts_checked, message);
      pkt2send.display("ERROR");
      pkt2cmp.display("ERROR");
      $finish;
    end
    $display("[NOTE]%t Packet #%0d %s", $realtime, pkts_checked++, message);
  endtask : check
  
endprogram: test
