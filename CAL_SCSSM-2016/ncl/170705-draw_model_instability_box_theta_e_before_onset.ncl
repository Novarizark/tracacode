;*************************************************************
;Aim: Cal MAM detrended T2m standard deviation
;
;Mission:
;   1. Read data from NCEP-DOE data
;   2. Post-post process
;   3. Output to yearly files
;                       Zhenning Li
;                       2015-05-05
;Last Edited:
;   2015-03-01  Create
;   2015-03-03  Change to fit HEAT Experiment
;   2015-04-05  Change to fit Team Server
;   2015-04-08  Change to fit ECMWF MONLTM MEAN 
;   2015-04-18  Change to caculate Q1
;   2015-04-18  Change to caculate daily Q1 in NCEP-DOE
;   2015-12-01  Change to fit T2M
;*************************************************************

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCL_SELFLIB/file_io.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
begin

;======================================================
;Variables List:
;======================================================

;global variables
    ;Define parameters

    ;for directory 
    g_var_name = (/"U","V","T"/)
    ;g_var_name = (/"uwnd","vwnd","air"/)
    g_font = 0.02
  
    ;BOB Early
    g_comp="early"
    g_special_year=(/1984, 1990, 1999, 2000, 2006, 2009/)-1979
    g_nsp_years=dimsizes(g_special_year)
    
    g_latN=22
    g_latS=5
    g_lonE=100
    g_lonW=87.5
    
    ;5, 12 works
    ep_strt=5
    ep_end=12

    clim_strt=87
    clim_end=108

    g_level=700
    g_level0=1000

    g_ctrl_datapath="/Users/zhenningli/data/CAL_SCSSM-2016/ensemble/ctrl/clim/"
    g_nudg_datapath="/Users/zhenningli/data/CAL_SCSSM-2016/ensemble/nudg/clim/"
    g_ctrl_name="CLIM-Trans-2015"
    g_nudg_name="Nudging"


    ctrl_in1     = addfile(g_ctrl_datapath+g_ctrl_name+".cam.h1.ESM.75-120.theta_es.nc", "r") 
    ctrl_var1=ctrl_in1->theta_es(:,ep_strt:ep_end,{g_level},{g_latS:g_latN},{g_lonW:g_lonE})
    nudg_in1     = addfile(g_nudg_datapath+g_nudg_name+".cam.h1.ESM.75-120.theta_es.nc", "r") 
    nudg_var1=nudg_in1->theta_es(:,ep_strt:ep_end,{g_level},{g_latS:g_latN},{g_lonW:g_lonE})
 
    ctrl_in1     = addfile(g_ctrl_datapath+g_ctrl_name+".cam.h1.ESM.75-120.theta_e.nc", "r") 
    ctrl_var2=ctrl_in1->theta_e(:,ep_strt:ep_end,{g_level0},{g_latS:g_latN},{g_lonW:g_lonE})
    nudg_in1     = addfile(g_nudg_datapath+g_nudg_name+".cam.h1.ESM.75-120.theta_e.nc", "r") 
    nudg_var2=nudg_in1->theta_e(:,ep_strt:ep_end,{g_level0},{g_latS:g_latN},{g_lonW:g_lonE})   
    
    
    ctrl_inst_var1=ctrl_var2-ctrl_var1
    nudg_inst_var1=nudg_var2-nudg_var1
    ctrl_var1@_FillValue=-999 
    nudg_var1@_FillValue=-999 
    ctrl_var1=where(ctrl_inst_var1 .gt. 0, ctrl_var1, ctrl_var1@_FillValue)
    nudg_var1=where(nudg_inst_var1 .gt. 0, nudg_var1, nudg_var1@_FillValue)
   
    ctrl_var1:=ctrl_var1(0:14,:,:,:)
    nudg_var1:=nudg_var1(0:14,:,:,:)
    ctrl_ip=ndtooned(ctrl_var1)
    nudg_ip=ndtooned(nudg_var1)

   
    qsort(ctrl_ip)
    qsort(nudg_ip)
    y1_box = new((/2,5/),"float")
    y1_avg = new((/2/),"float")

    n_ctrl=num(.not.ismissing(ctrl_ip))
    n_nudg=num(.not.ismissing(nudg_ip))

    ctrl_strt=dimsizes(ctrl_ip)-n_ctrl
    nudg_strt=dimsizes(nudg_ip)-n_nudg
    y1_box(0,:) = (/ctrl_ip(ctrl_strt+floattoint(n_ctrl*0.1)),ctrl_ip(ctrl_strt+floattoint(n_ctrl/4)),ctrl_ip(ctrl_strt+floattoint(n_ctrl/2)),ctrl_ip(ctrl_strt+floattoint(3*n_ctrl/4)),ctrl_ip(ctrl_strt+floattoint(n_ctrl*0.9))/)
    y1_box(1,:) = (/nudg_ip(nudg_strt+floattoint(n_nudg*0.05)),nudg_ip(nudg_strt+floattoint(n_nudg/4)),nudg_ip(nudg_strt+floattoint(n_nudg/2)),nudg_ip(nudg_strt+floattoint(3*n_nudg/4)),nudg_ip(nudg_strt+floattoint(n_nudg*0.95))/)
    print(y1_box)
    y1_avg(0) = avg(ctrl_ip)
    y1_avg(1) = avg(nudg_ip)
    
    ;y1_box(0,:)=y1_box(0,:)/y1_avg(0)
    ;y1_box(1,:)=y1_box(1,:)/y1_avg(0)

    x=(/-1,1/)
;********************************************************
    ; create the plot
    ;********************************************************  
    g_fig_name="../fig/nudging/box-theta-es" 
   wks = gsn_open_wks("png",g_fig_name)  ; open a ps file
   ;plot_box = new((/4/),graphic)


    res            = True                         ; plot mods desired
    res@tmXBLabels = (/"CTRL", "NUDG"/) ; labels for each box
   res@tmXBLabelFontHeightF = g_font
   res@tmYLLabelFontHeightF = g_font
   res@tiMainFontHeightF    = g_font

    ;**********************************************
    ; resources for polylines that draws the boxes
    ;**********************************************  
    llres                   = True          
    llres@gsLineThicknessF  = 3.0                 ; line thickness 
    ;**********************************************
    ; resources that control color and width of boxes
    ;**********************************************  
    opti          = True            
    opti@boxWidth = .5              ; Width of box (x units)
    opti@boxColors = (/"blue","red"/)     ; Color of box(es)
    ;***********************************************
    
    
   ;***********************************************
   ;add polymarker res
   ;***********************************************
   mres               = True                     ; marker mods desired
   mres@gsMarkerIndex = 3                        ; polymarker style
   mres@gsMarkerSizeF = 20.                      ; polymarker size
   mres@gsMarkerColor = "navy blue"                    ; polymarker color
   mres@gsMarkerThicknessF = 2.0

   ;***********************************************
   ;add refline res
   ;***********************************************

    lnres = True
    lnres@gsLineThicknessF = 3.0
    
    ;siglnres@gsLineThicknessF = 3.0
    ;siglnres@gsLineDashPattern = 2
    ;siglnres@gsLineColor = "red"
    
    res@tiMainString="Theta-es distribution"
   plot_box = boxplot(wks,x,y1_box,opti,res,llres) ; All 3 options used...
   dum2 = gsn_add_polymarker(wks,plot_box,x,y1_avg,mres) 

    gsn_panel(wks,plot_box,(/1,1/),False)
end
