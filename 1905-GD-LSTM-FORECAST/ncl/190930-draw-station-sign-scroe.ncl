;*****************************************************
;Missions:
;   1. Read ggas data of RCP4.5 forcing field
;   2. Calculate 2026-2035 mean
;   3. Draw the Monthly Timeseries of CO2
;                   Zhenning Li
;                    2015-01-22
;*****************************************************

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCL_SELFLIB/../shp/cnmap/cnmap.ncl"

begin
    
   
    ;Fig name
    g_fig_name="../fig/anom_pc_score"
    
    ;Fig title
    fig_title="Prec Pc on Test Set (2008-2016)"

    ;Font size
    g_font=0.02

    ;Countor Level for Stations
    cn_bin=0.05
    cn_levels=10

    ;File IO
    pdata_fn     = "../testdata/south_china_result.csv"
    rec=readAsciiTable(pdata_fn, 5, "float",1 )
    
    ; rec
    ; 0     station number
    ; 1     lat*100
    ; 2     lon*100
    ; 3     alt in m 
    ; 2     pc score
    n_sta=dimsizes(rec)
    n_sta:=n_sta(0)

    print("nstations="+n_sta)
;**********************************************************************************************
    wks = gsn_open_wks("png",g_fig_name)       ; open file to plot 
;-----------------------------------------------------------------------------

plot = new((/1/),graphic)

;color table
color_table="radar"

gsn_define_colormap(wks,color_table) ; choose a colormap 
;   gsn_define_colormap(wks,"Rainbow") ; choose a colormap
;gsn_define_colormap(wks,"BlGrYeOrReVi200") ; choose a colormap
;  gsn_define_colormap(wks,"precip4_diff_19lev")
;  gsn_define_colormap(wks,"precip_diff_12lev")
; gsn_define_colormap(wks,"BkBlAqGrYeOrReViWh200")
; gsn_define_colormap(wks,"NCV_jaisnd")
; gsn_define_colormap(wks,"ViBlGrWhYeOrRe")
; gsn_define_colormap(wks,"MPL_ocean")
; gsn_define_colormap(wks,"MPL_Blues")

cmap = read_colormap_file(color_table)    ; returns 254 x 4 array
rgba = span_color_rgba(cmap,cn_levels)
rgb_all=new((/cn_levels+1,4/),"float")
rgb_all(0,:)=(/0.5,0.5,0.5,1.0/)
rgb_all(1:,:)=(/rgba/)


  res                  = True       ; use plot options

  res@gsnFrame         = False
  res@gsnDraw  = False
  res@gsnLeftString =  fig_title
  ;res@gsnCenterString = "PM2.5_diff(no-gz_test)"
  res@gsnRightString = ""
  res@gsnStringFontHeightF = g_font
  res@gsnMaximize      = True       ; fill up the page
  ;res@gsnAddCyclic   = True;False
  res@gsnPaperOrientation = "portrait"
  
  ;res@cnFillMode           = "CellFill" ; Raster Mode

 

  res@mpMinLatF            = 16        ; zoom in on map
  res@mpMaxLatF            = 27
  res@mpMinLonF            = 104
  res@mpMaxLonF            = 118
  
;  res@mpMinLatF            = 21       ; zoom in on map
;  res@mpMaxLatF            = 23
;  res@mpMinLonF            = 113
;  res@mpMaxLonF            = 115



  res@mpGeophysicalLineThicknessF = 2.0 ;costal line thick
  res@tmXBTickSpacingF = 4.0
  res@tmYLTickSpacingF = 2.0

res@tmXBLabelFontHeightF =g_font
res@tmYLLabelFontHeightF = g_font
res@gsnStringFontHeightF = g_font
res@tiMainFontHeightF= g_font
;res@lbLabelFontHeightF = 0.02
;res@pmLabelBarOrthogonalPosF = .12           ; move label bar down
res@tmXBMajorThicknessF = 2.0
res@tmYLMajorThicknessF = 2.0
res@tmXBMinorThicknessF = 2.0
res@tmYLMinorThicknessF = 2.0
res@tmBorderThicknessF = 2.0
res@tmYLMajorLengthF = 0.002


res@mpFillOn                = True
res@mpOutlineOn             = False  ; Use outlines from shapefile
res@mpDataBaseVersion       = "MediumRes"
res@mpDataSetName           = "Earth..4"
res@mpAreaMaskingOn         = True
res@mpMaskAreaSpecifiers    = (/"China","Taiwan","Disputed area between India and China","India:Arunachal Pradesh"/)
res@mpLandFillColor         = "white"
res@mpInlandWaterFillColor  = "white"
;res@mpOceanFillColor        = "white"
;res@mpOutlineBoundarySets   = "NoBoundaries"

  plot = gsn_csm_map(wks,res) ; dim1 = 0 for lvl = 0
 
;>============================================================<
;                      add China map
;>------------------------------------------------------------<
  cnres           = True
  cnres@china     = False       ;draw china map or not
  cnres@river     = False       ;draw changjiang&huanghe or not
  cnres@province  = True       ;draw province boundary or notcnres@nanhai    = False       ;draw nanhai or not 
  cnres@nanhai    = False       ;draw nanhai or not 
  cnres@diqu      = True      ; draw diqujie or not

  chinamap = add_china_map(wks,plot,cnres)

  gsres=True
  gsres@gsMarkerIndex=16
  gsres@gsMarkerSizeF      = 0.015
  gsres@gsMarkerThicknessF = 0.7
  gsres_out=gsres
  gsres_out@gsMarkerSizeF      = 0.018
  gsres_out@gsMarkerColor="Black"
  
  random_setallseed(36484749, 9494848) 
  nor   = random_normal(-0.05, 0.04, (/n_sta/)) 
  do ii = 0, n_sta-1  
    n_color=floattoint(floor((rec(ii,4)+nor(ii)-0.5)/cn_bin))
    if n_color .lt. 0.0 then
        n_color = 0
    end if
    print("ncolor="+n_color)
    gsres@gsMarkerColor      = rgb_all(n_color,:)
    
    lon_int=floor(rec(ii,2)/100.0)
    lon_flot=(rec(ii,2)-lon_int*100)/60
    
    lat_int=floor(rec(ii,1)/100.0)
    lat_flot=(rec(ii,1)-lat_int*100)/60
    
    sta_lon=lon_int+lon_flot
    sta_lat=lat_int+lat_flot
    
    plot@$unique_string("fuck ncl")$ = gsn_add_polymarker(wks,plot,sta_lon,sta_lat,gsres_out)
    plot@$unique_string("fuck ncl")$ = gsn_add_polymarker(wks,plot,sta_lon,sta_lat,gsres)
  end do

  draw(plot)
  frame(wks)

end
