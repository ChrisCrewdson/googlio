Magickly.add_convert_factory :mustachify do |c|
  c.convert_args do |eye_num_param, convert|
    identity = convert.pre_identify
    width = identity[:width]
    height = identity[:height]
    # resize to smaller than 900px, because Face.com downsizes the image to this anyway
    # TODO move resize inside of Mustachio.face_data
    faces = convert.image.thumb('900x900>').face_data_as_px(width, height)

    commands = ['-alpha Background -background Transparent']
    faces.each do |face|
      eye_num = case eye_num_param
                   when true
                     0
                   when 'true'
                     0
                   when 'rand'
                     rand(Mustachio.eyes.size)
                   else
                     eye_num_param.to_i
                   end

      eye = Mustachio.eyes[eye_num]

      face['eye_center'] ||= {
        'x' => ((face['eye_left']['x'] + face['eye_right']['x']) / 2.0),
        'y' => ((face['eye_left']['y'] + face['eye_right']['y']) / 2.0)
      }

      # perform transform such that the mustache is the height
      # of the upper lip, and the bottom-center of the stache
      # is mapped to the center of the mouth

      rotation = Math.atan(( face['eye_right']['y'] - face['eye_left']['y'] ).to_f / ( face['eye_right']['x'] - face['eye_left']['x'] ).to_f ) / Math::PI * 180.0
      desired_height = Math.sqrt(
                                 ( face['nose']['x'] - face['eye_center']['x'] ).to_f**2 +
                                 ( face['nose']['y'] - face['eye_center']['y'] ).to_f**2
                                 )
      eye_intersect = eye['height'] - eye['eye_overlap']
      scale = desired_height / eye_intersect
      srt_params = [
                    [ eye['width'] / 2.0, eye_intersect - eye['vert_offset'] ].map{|e| e.to_i }.join(','), # bottom-center of stache
                    scale, # scale
                    rotation, # rotate
                    [ face['eye_center']['x'], face['eye_center']['y'] ].map{|e| e.to_i }.join(',') # middle of mouth
                   ]
      srt_params_str = srt_params.join(' ')

      commands << "\\( #{eye['file_path']} +distort SRT '#{srt_params_str}' \\)"
    end
    commands << "-flatten"

    commands.join(' ')
  end
end
