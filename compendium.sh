# From the directory where this file is located, execute (this will make things easier):
topdir=`pwd`

# Other useful shortcuts:
pyline=$topdir/BART/modules/transit/pylineread/src/pylineread.py
transit=$topdir/BART/modules/transit/transit/transit
bart=$topdir/BART/BART.py

# Clone and compile the BART code:
git clone --recursive https://github.com/exosports/BART BART/
cd $topdir/BART
git checkout 862cb09
cd $topdir/BART/modules/transit
git checkout c698128
make
cd $topdir/BART/modules/MCcubed
git checkout 7487a47
make


# ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# Download the HITRAN CIA data:
cd $topdir/inputs/CIA
wget --user=HITRAN --password=getdata -N https://www.cfa.harvard.edu/HITRAN/HITRAN2012/CIA/Main-Folder/H2-H2/H2-H2_2011.cia
wget --user=HITRAN --password=getdata -N https://www.cfa.harvard.edu/HITRAN/HITRAN2012/CIA/Main-Folder/H2-He/H2-He_2011.cia

# Download Partridge and Schwenke H2O opacity data:
cd $topdir/inputs/opacity/H2O
wget http://kurucz.harvard.edu/molecules/h2o/h2ofastfix.bin
wget http://kurucz.harvard.edu/molecules/h2o/h2opartfn.dat

# Download the HITEMP CO opacity data:
cd $topdir/inputs/opacity/CO
wget https://hitran.org/hitemp/data/bzip2format/05_HITEMP2019.par.bz2
bzip2 -d 05_HITEMP2019.par.bz2


# Download the HITEMP CO2 opacity data:
cd $topdir/inputs/opacity/CO2
wget -i wget_HITEMP_CO2.txt
unzip '*.zip'

# Download the ExoMol CH4 data:
cd $topdir/inputs/opacity/CH4
# Go to: http://www.exomol.com/xsecs/12C-1H4
# and fetch data for:
#   delta nu = 1.0
#   nu_min =   500
#   nu_max = 11999
# for a range of temperatures from 1000 K to 2000 K in steps of 100 K.
# Be sure to check the 'two-column output' option.

# Download the TiO opacity data:
cd $topdir/inputs/opacity/TiO
wget http://kurucz.harvard.edu/molecules/tio/tioschwenke.bin
wget http://kurucz.harvard.edu/molecules/tio/tiopart.dat

# Download the VO opacity data:
# Contact Bertrand Plez for the VO line list:
#   http://www.pages-perso-bertrand-plez.univ-montp2.fr/
# Save the file as 'linelistVO_ALL.dat' in $topdir/inputs/opacity/VO


# ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# Format the HITRAN CIA data for Transit:
cd $topdir/inputs/CIA
$topdir/BART/modules/transit/scripts/HITRAN_CIA_format.py H2-H2_2011.cia CIA_HITRAN_H2H2_0200-3000K_1.0-500um.dat  50  10
$topdir/BART/modules/transit/scripts/HITRAN_CIA_format.py H2-He_2011.cia CIA_HITRAN_H2He_0200-9900K_0.5-500um.dat  50  10

# Format cross-section data for Transit:
cd $topdir/inputs/opacity/CH4
$topdir/BART/modules/transit/scripts/Yurchenko_CH4_format.py *.sigma


# ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# Run Transit for CIA:
cd $topdir/run01_CIA/
$transit -c H2+He-CIA_Borysow.cfg
$transit -c H2+He-CIA_HITRAN.cfg

# Run Transit:
cd $topdir/run02_H2O/
$pyline  -c pyline_H2O-pands_1-20um.cfg
$transit -c Transit_H2O-pands.cfg

# Run Transit:
cd $topdir/run03_CO/
$pyline  -c pyline_CO-HITEMP_1-20um.cfg
$transit -c Transit_CO-HITEMP.cfg

# Run Transit:
cd $topdir/run04_CO2/
$pyline  -c pyline_CO2-HITEMP_1-20um.cfg
$transit -c Transit_CO2-HITEMP.cfg

# Run Transit:
cd $topdir/run05_CH4/
$transit -c Transit_CH4-ExoMol.cfg

# Run Transit to produce a TiO-VO opacity file:
cd $topdir/run06_TiO-VO/
$pyline  -c pyline_TiO-VO_0.4-1.6um.cfg
$transit -c Transit_TiO-VO.cfg --justOpacity

# Figures 4, 5, and 6:
cd $topdir
./figure_CIA.py
./figure_H2O-CO-CO2-CH4-emission.py
./figure_TiO-VO_opacity.py

# ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

# Download the HITRAN/HITEMP data:
cd $topdir/inputs/opacity/H2O
wget --user=HITRAN --password=getdata -N -i wget_HITEMP_H2O.txt
unzip '*.zip'
# FINDME: Replace this with exomol file

cd $topdir/inputs/opacity/CH4
wget https://hitran.org/hitemp/data/bzip2format/06_HITEMP2020.par.bz2
bzip2 -d 06_HITEMP2020.par.bz2

# Run pylineread:
cd $topdir/run07_HAT-P-11b_BART
$pyline -c pyline_hitemp_CH4_CO_CO2_exomol_H2O_0.34-5.5um.cfg

# Modifications to the BART code to account for transit-depth offsets
cp $topdir/inputs/ancil/BART.py     $topdir/BART/
cp $topdir/inputs/ancil/BARTfunc.py $topdir/BART/code/
cp $topdir/inputs/ancil/bestFit.py  $topdir/BART/code/


# Generate atmospheric and opacity files
cd $topdir/run07_HAT-P-11b_BART
$bart -c BART_inputs_fraine.cfg --justOpacity
$bart -c BART_inputs_chachan.cfg --justOpacity

# Make atmfile with uniform abundances for H2O, CO, CO2, and CH4:
cd $topdir
python $topdir/inputs/ancil/make_uniform.py

# Run BART
cd $topdir/run07_HAT-P-11b_BART
$bart -c BART_HATP11b_fraine.cfg
$bart -c BART_HATP11b_chachan_all.cfg
$bart -c BART_HATP11b_chachan_hst.cfg

# Figure 13:
cd $topdir
./figure_HATP11b_retrieval_fraine.py
./figure_HATP11b_retrieval_chachan.py
