transcript on

vlib work

vlog -sv +incdir+./ ./rtl/*.sv
vlog -sv +incdir+./ ./tb/*.sv

vsim -t 1ns -voptargs="+acc" find_max_tb

add wave -position end  sim:/find_max_tb/rst_n
add wave -position end  sim:/find_max_tb/clk
add wave -position end  sim:/find_max_tb/start
add wave -position end  sim:/find_max_tb/in
add wave -position end  sim:/find_max_tb/max_val
add wave -position end  sim:/find_max_tb/done

run -all

