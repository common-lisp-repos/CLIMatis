(cl:in-package #:clim3-calendar)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Date manipulation.

;;; This function is similar to DECODE-UNIVERSAL-TIME, except that it
;;; does not return seconds and minutes; only hour, day, month, year,
;;; and day-of-week. 
(defun dut (universal-time)
  (multiple-value-bind (ss mm hh d m y dow)
      (decode-universal-time universal-time 0)
    (declare (ignore ss mm))
    (values hh d m y dow)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Butcon (name taken from the book by Alan Cooper).
;;;
;;; It is a combination of a button and an icon.  When the pointer
;;; enters the zone, then it becomes darker.  When the button is
;;; pressed when the pointer is in the zone, the buton becomes aremed.
;;; When the button is released and the butcon is armed, then the
;;; action is executed.  The butcon becomes disarmed if the pointer
;;; leaves the zone, so that leaving the zone while the button is
;;; pressed prevents the action from being executed when the button is
;;; released.

(defclass action-button-handler (clim3:button-handler)
  ((%armedp :initform nil :accessor armedp)
   (%action :initarg :action :reader action)))

(defmethod clim3:handle-button-press
    ((handler action-button-handler) button-code modifiers)
  (declare (ignore button-code modifiers))
  (setf (armedp handler) t))

(defmethod clim3:handle-button-release
    ((handler action-button-handler) button-code modifiers)
  (declare (ignore button-code modifiers))
  (when (armedp handler)
    (setf (armedp handler) nil)
    (funcall (action handler))))

(defclass butcon (clim3:pile clim3:visit clim3:highlight)
  ((%armedp :initform nil :accessor armedp)
   (%action :initarg :action :reader action)
   (%wrap :initform (clim3:wrap) :reader wrap)
   (%icon :initarg :icon :reader icon))
  (:default-initargs :inside-p (constantly t)))
  
(defmethod initialize-instance :after ((zone butcon) &key &allow-other-keys)
  (setf (clim3:depth (wrap zone)) 100)
  (setf (clim3:children zone)
	(list (clim3:masked
	       (clim3:make-color 0.0 0.0 0.0)
	       (icon zone))
	      (wrap zone))))

(defmethod clim3:highlight ((zone butcon))
  (setf (clim3:children (wrap zone))
	(clim3:translucent (clim3:make-color 0.0 0.0 0.0) 0.2d0)))

(defmethod clim3:unhighlight ((zone butcon))
  (setf (clim3:children (wrap zone))
	'()))

(defmethod clim3:enter progn ((zone butcon))
  (setf clim3:*button-handler*
	(make-instance 'action-button-handler
	  :action (action zone))))
	      
(defmethod clim3:leave progn ((zone butcon))
  (setf clim3:*button-handler* clim3:*null-button-handler*))

(defun butcon (icon action)
  (make-instance 'butcon
    :action action
    :icon icon))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; GUI.

;;; The value is the current absolute week number, where the first
;;; week of year 1900 is considered to be absolute week number 0.
;;; Lucky for us, the first week of 1900 started on a Monday, and that
;;; is also how ISO 8601 defines the week. 
(defparameter *current-week* 0)

(defparameter *dayname-text-style*
  (clim3:text-style :free :sans :roman 10))

(defparameter *day-number-text-style*
  (clim3:text-style :free :sans :bold 20))

(defparameter *month-year-text-style*
  (clim3:text-style :free :sans :bold 15))

(defparameter *hour-text-style*
  (clim3:text-style :free :fixed :roman 10))

(defparameter *toolbar-text-style*
  (clim3:text-style :free :fixed :roman 20))

(defparameter *follow-hour-space* 5)

(defparameter *background* (clim3:make-color 0.95d0 0.95d0 0.95d0))

(defparameter *black* (clim3:make-color 0.0d0 0.0d0 0.0d0))

(defun hour-zone ()
  (clim3:sponge))

(defun vline ()
  (clim3:hbrick
   1
   (clim3:opaque (clim3:make-color 0.3d0 0d0 0d0))))

(defun hline ()
  (clim3:vbrick
   1
   (clim3:opaque (clim3:make-color 0.3d0 0d0 0d0))))

(defparameter *month-year* (clim3:hbrick 200 (clim3:center)))

(defun number-to-month-name (number)
  (elt '("Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec") (1- number)))

(defun set-month-year ()
  (let* ((utime (* *current-week* #.(* 7 24 60 60)))
         (mstart (third (multiple-value-list (dut utime)))))
    (multiple-value-bind (hh d mend year) (dut (+ utime (* 6 #.(* 24 60 60))))
      (declare (ignore hh d))
      (setf (clim3:children (clim3:children *month-year*))
            (clim3-text:text (if (= mstart mend)
                                 (format nil "~a ~d" (number-to-month-name mstart) year)
                                 (format nil "~a/~a ~d"
                                         (number-to-month-name mstart)
                                         (number-to-month-name mend)
                                         year))
                             *month-year-text-style* *black*)))))

;;; The day numbers are wrap zones, and the child of each such wrap
;;; zone will be modified to reflect what is currently on display. 
(defparameter *day-numbers-of-week*
  (loop repeat 7
	collect (clim3:wrap)))

(defun set-day-numbers ()
  (let ((utime (* *current-week* #.(* 7 24 60 60))))
    (loop for i from 0 below 7
	  for dno = (second (multiple-value-list
			     (dut (+ utime (* i #.(* 24 60 60))))))
	  for wrap in *day-numbers-of-week*
	  do (setf (clim3:children wrap)
		   (clim3-text:text
		    (format nil "~2,'0d" dno)
		    *day-number-text-style*
		    *black*)))))

(defun dayname-zone (name number)
  (clim3:vbrick
   40
   (clim3:vbox*
    (clim3:sponge)
    (clim3:hbox*
     (clim3:hbrick 5)
     (clim3:hbrick
      40
      (clim3:vbox*
       (clim3:sponge)
       number))
     (clim3:hbrick
      40
      (clim3:vbox*
       (clim3:sponge)
       (clim3-text:text name
			*dayname-text-style*
			*black*)
       (clim3:sponge)))
     (clim3:sponge))
    (clim3:vbrick 2))))

(defun day-names ()
  (clim3:hbox 
   (loop for name in '("Mon" "Tue" "Wed" "Thu" "Fri" "Sat" "Sun")
	 for number in *day-numbers-of-week*
	 collect (dayname-zone name number))))

(defun day-zone ()
  (clim3:hbox*
   (clim3:vbox
    (cons (hline)
	  (loop repeat 24
		collect (hour-zone)
		collect (hline))))
   (vline)))

(defun grid-zones ()
  (clim3:hbox
   (cons (vline)
	 (loop repeat 7
	       collect (day-zone)))))

(defun hours ()
  (let ((color (clim3:make-color 0.0d0 0.0d0 0.0d0 )))
    (clim3:vbox
     (cons (clim3-text:text "00:00" *hour-text-style* color)
	   (loop for hour from 1 to 24
		 collect (clim3:sponge)
		 collect (clim3-text:text (format nil "~2,'0d:00" (mod hour 24))
					  *hour-text-style* color))))))
(defun time-plane ()
  (clim3:hbox*
   (hours)
   (clim3:hbrick *follow-hour-space*)
   (clim3:vbox*
    (clim3:vbrick 10)
    (grid-zones)
    (clim3:vbrick 10))))

(defun calendar-zones ()
  (clim3:pile*
   (clim3:brick
    1000 700
    (clim3:hbox*
     (clim3:vbox*
      (clim3:hbox*
       (clim3:hbrick 60)
       (day-names))
      (time-plane))
     (clim3:hbrick 10)))
   (clim3:opaque *background*)))

(defun previous-week ()
  (decf *current-week*)
  (set-month-year)
  (set-day-numbers))

(defun next-week ()
  (incf *current-week*)
  (set-month-year)
  (set-day-numbers))

(defparameter *icons* (clim3-icons:make-icons 20))

(defun toolbar ()
  (clim3:pile*
   (clim3:hbox*
    (clim3:sponge)
    (butcon (clim3-icons:find-icon *icons* :left) #'previous-week)
    *month-year*
    (butcon (clim3-icons:find-icon *icons* :right) #'next-week)
    (clim3:sponge))
   (clim3:opaque *background*)))

(defun calendar ()
  (setf *current-week* (floor (get-universal-time) #.(* 7 24 60 60)))
  (set-month-year)
  (set-day-numbers)
  (let ((port (clim3:make-port :clx-framebuffer))
	(root (clim3:vbox*
	       (toolbar)
	       (calendar-zones))))
    (clim3:connect root port)
    (let ((clim3:*port* port))
      (loop for keystroke = (clim3:read-keystroke)
	    until (eql (car keystroke) #\q)))
    (clim3:disconnect root port)))
