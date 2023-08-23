//----------------------------------------------------------------------
//   Copyright 2012 Mentor Graphics Corporation
//   All Rights Reserved Worldwide
//
//   Licensed under the Apache License, Version 2.0 (the
//   "License"); you may not use this file except in
//   compliance with the License.  You may obtain a copy of
//   the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in
//   writing, software distributed under the License is
//   distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
//   CONDITIONS OF ANY KIND, either express or implied.  See
//   the License for the specific language governing
//   permissions and limitations under the License.
//----------------------------------------------------------------------

class word_format_int_vseq extends uart_vseq_base;

`uvm_object_utils(word_format_int_vseq)

function new(string name = "word_format_int_vseq");
  super.new(name);
endfunction

task body;
  uart_config_seq     setup = uart_config_seq::type_id::create("setup");
  uart_int_enable_seq ien = uart_int_enable_seq::type_id::create("ien");
  uart_int_tx_rx_seq  isr = uart_int_tx_rx_seq::type_id::create("isr");
  uart_rx_seq         rx_serial = uart_rx_seq::type_id::create("rx_serial");
  uart_host_rx_seq    rx_poll = uart_host_rx_seq::type_id::create("rx_poll");
  uart_host_tx_seq    tx_poll = uart_host_tx_seq::type_id::create("tx_poll");
  uart_wait_empty_seq wait_empty = uart_wait_empty_seq::type_id::create("wait_empty");

  bit[7:0] lcr;
  bit[15:0] divisor;
  bit[1:0] fcr;
  // bit[7:0] i;

  lcr = 0;
  divisor = 2;

  rx_serial.no_rx_chars = 0;
  // rx_serial.no_errors = 1;
  rx_serial.no_errors = 0;

  // i = 0;
  // setup.randomize()进行对象setup里rand变量的随机化，并添加约束条件约束 LCR DIV的值。
  repeat(128) begin
    assert(setup.randomize() with {setup.LCR == lcr;
                                   setup.DIV == divisor;
                                   setup.FCR == 2'b11;});
 
    setup.start(apb);
    ien.IER = 4'h3;     // 4'b0011 对rx tx 两个对应的FIFO中断使能
    ien.start(apb);
    rx_serial.baud_divisor = divisor;
    rx_serial.lcr = lcr;
    rx_uart_config.baud_divisor = divisor;
    rx_uart_config.lcr = lcr;
    tx_uart_config.baud_divisor = divisor;
    tx_uart_config.lcr = lcr;

    assert(isr.randomize() with {no_tx_chars inside {[1:20]};});
    isr.FCR = setup.FCR;
    case(setup.FCR)
      2'b00: isr.no_rx_chars = $urandom_range(2, 10);
      2'b01: isr.no_rx_chars = $urandom_range(4, 12);
      2'b10: isr.no_rx_chars = $urandom_range(8, 16);
      2'b11: isr.no_rx_chars = $urandom_range(14, 22);
    endcase
    rx_serial.no_rx_chars = isr.no_rx_chars;
    tx_poll.no_tx_chars = 1;
    tx_poll.start(apb);

    fork
      begin  // 当接收数据的字符数 大于 接收FIFO阈值时 触发中断 或者 在中断控制中发送字符数大于1时触发001中断（发送寄存器tx保持为空）
        while((isr.no_rx_chars > isr.rx_fifo_threshold) || (isr.no_tx_chars > 0)) begin
          if(!cfg.get_interrupt_level()) begin
            cfg.wait_for_interrupt();
          end
          isr.start(apb);
        end
        rx_poll.no_rx_chars = isr.no_rx_chars;
        rx_poll.start(apb);
      end
      rx_serial.start(uart);
    join
    wait_empty.start(apb);
    lcr = lcr + 1;
    // lcr = (lcr > 63) ? 0 : (lcr + 1);   
    // // $display("lcr: ", lcr);
    // i++;
    // if (i > 50) begin
    //   rx_serial.no_errors = 1;
    // end
  end

endtask: body

endclass: word_format_int_vseq