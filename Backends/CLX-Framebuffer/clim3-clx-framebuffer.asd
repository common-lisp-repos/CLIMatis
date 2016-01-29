(in-package #:common-lisp-user)

(asdf:defsystem :clim3-clx-framebuffer
  :depends-on (:climatis-packages
	       :clim3-port :clim3-zone :clim3-layout :clim3-graphics
	       :clim3-paint :clim3-color :clim3-input  :clim3-text-style
	       :clim3-text :clim3-rendering :clim3-meter
	       :clim3-truetype :camfer :clx :cl-fad)
  :components
  ((:file "clx-framebuffer-packages" :depends-on ())
   (:file "clx-framebuffer" :depends-on ("clx-framebuffer-packages"))
   (:file "paint"
    :depends-on ("clx-framebuffer-packages" "clx-framebuffer"))))

	    
