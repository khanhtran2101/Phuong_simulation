# Enable GPU
package gpu 1                            # Use GPU
suffix gpu                               # Run all GPU-compatible commands on GPU

units             metal                       
boundary          s s p                    
atom_style        atomic                 

read_data         LAMMPSDATAFILE1.txt

pair_style        eam/alloy
pair_coeff        * * CuNi.eam.alloy Cu Ni

neighbor          2.0 bin 
neigh_modify      every 1 delay 5 check yes               

compute           1 all stress/atom NULL
compute           eng all pe/atom 
compute           eatoms all reduce sum c_eng

variable          natoms equal "count(all)" 
variable          teng equal "c_eatoms"
variable          ecoh equal "v_teng/v_natoms"

reset_timestep    0                                        
thermo            10000                             
thermo_style      custom step temp pe ke etotal v_ecoh lx ly lz press 

min_style         cg                                           
minimize          1e-25 1e-25 10000 10000                         

reset_timestep    0
timestep          0.001                                         
velocity          all create 300 5812775 dist gaussian mom yes rot no

fix               1 all npt temp 300 300 0.1 z 0 0 1 drag 0.0
fix               2 all print 500 "${ecoh}" file Ecoh-Cu.txt screen no

run               50000
unfix             1
unfix             2

variable          tmp equal "lz"
variable          L0 equal ${tmp}
print             "Initial Length, L0: ${L0}"

reset_timestep    0
fix               1 all nvt temp 300 300 0.1
variable          srate equal 1.0e10
variable          srate1 equal "v_srate / 1.0e12"
fix               2 all deform 1 z erate ${srate1} units box remap x

variable 		strain equal "(lz - v_L0)/v_L0"
variable 		p0 equal "v_strain"

variable 		p1 equal "-pxx/10000"
variable 		p2 equal "-pyy/10000"
variable 		p3 equal "-pzz/10000"

variable 		p12 equal "-pxy/10000"
variable 		p23 equal "-pyz/10000"
variable 		p13 equal "-pxz/10000"

variable 		fv equal "sqrt(((v_p2-v_p3)^2+(v_p3-v_p1)^2+(v_p1-v_p2)^2+6*(v_p12^2+v_p23^2+v_p13^2))/2)"

fix 			3 all print 500 "${p0} ${p3} ${fv}" file Stress-Strain.Cu.txt screen no

thermo            10000
thermo_style      custom step v_strain temp v_p3 v_fv pe ke etotal press

dump              1 all custom 10000 dump.Cu id type x y z               

restart           200000 restart.Cu
run               200000

