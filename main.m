function project
    infile = 0;  % Input file.
    while 1
        % Open image to restore.
        [infile, inpath] = uigetfile('*.*', 'Select Damaged File to Open');
        if infile == 0  % Exit if no file was selected.
            return
        end
        try
            I = double(imread(strcat(inpath, infile))) / 255;
            break
        catch
            waitfor(errordlg('The selected file was not an image.'));
        end
    end
    
    % Figure parameters.
    figure( ...
        'numberTitle', 'off', ...
        'Name', 'Image repair');
    
    % Create an empty binary noise mask.
    noise_mask = false([size(I, 1) size(I, 2)]);
    r = I;  % Copy of the original image, to be masked.
    
    % Informational text, telling the user what to do.
    text = uicontrol( ...
        'Style', 'text', ...
        'String', 'Noise masking phase.', ...
        'Position', [0, 0, 400, 20]);
    % Masking button controls.
    controls = [ ...
        uicontrol( ...  % Button to clear mask.
            'Style', 'pushbutton', ...
            'String', 'Clear mask', ...
            'Position', [0, 20, 100, 20], ...
            'Callback', @clear_mask), ...
        uicontrol( ...  % Button to stop masking.
            'Style', 'pushbutton', ...
            'String', 'Stop masking', ...
            'Position', [0 40 100 20], ...
            'Enable', 'off', ...  % Only enable once a mask is made.
            'Callback', @stop_masking), ...
        uicontrol( ...  % Button to add a mask.
            'Style', 'pushbutton', ...
            'String', 'Add mask', ...
            'Position', [0 60 100 20], ...
            'Callback', @add_mask)];
        
    imshow(r);
    % Wait for user input from this point on.
    
    % Masking button control functions.
    function [] = add_mask(h, ~)
        % Add a polygon to the noise mask.
        is_first = get(controls(2), 'Enable');  % Don't allow stopping during masking.
        
        set(controls(2), 'Enable', 'off');  % Don't allow stopping during masking.
        set(h, 'Enable', 'off');  % Don't allow adding another mask during masking.
        
        try  % Might get interrupted.
            % Ask user to mask the noise.
            noise_mask = noise_mask | roipoly;
        catch
            % Re-enable buttons, keeping in mind the previous state.
            set(h, 'Enable', 'on');
            set(controls(2), 'Enable', is_first);
            return
        end
        
        % Re-enable buttons.
        set(h, 'Enable', 'on');
        set(controls(2), 'Enable', 'on');
        r = I .* repmat(~noise_mask, [1 1 3]);
        imshow(r);
    end

    function [] = clear_mask(~, ~)
        % Clear the current noise mask.
        set(controls(2), 'Enable', 'off');  % Don't allow stopping untila mask is selected.
        noise_mask = false([size(I, 1) size(I, 2)]);
        r = I;  % image masked with noise mask.
        imshow(r);
    end

    function [] = stop_masking(~, ~)
        % Stop the masking step and initialize the selecting of subimages.
        set(text, 'String', 'Select the repair subimage, double click the rectangle to finish.');
        for control = controls  % Remove masking buttons;
            delete(control);
        end
        controls = [];
        % Start the subimage selection.
        % Button controls.
        controls = [ ...
            uicontrol( ...  % Button to add a mask.
                'Style', 'pushbutton', ...
                'String', 'New subimages', ...
                'Position', [0 40 100 20], ...
                'Callback', @new_subimages), ...
            uicontrol( ...  % Create slider for the number of iterations.
                'Style', 'slider', ...
                'Min', 1, ...
                'Max', 50, ...
                'Value', 10, ...
                'SliderStep', [1 1]/20, ...
                'Position', [100 20 300 20]), ...
            uicontrol( ...  % Create slider for the number of iterations.
                'Style', 'text', ...
                'String', 'Iterations: 10', ...
                'HorizontalAlignment', 'left', ...
                'Position', [0 20 100 20]), ...
            uicontrol( ...  % Save button for image.
                'Style', 'pushbutton', ...
                'String', 'Save', ...
                'Position', [0 60 100 20], ...
                'Callback', @(~, ~)save_image()), ...
            uicontrol( ...  % Allow selection of algorithm, A1 or A2.
                'Style', 'popupmenu', ...
                'String', 'A1|A2|A3', ...
                'Value', 3, ...
                'Position', [100 40 40 20])];
        hSlider = handle(controls(2));
        hListener = handle.listener(hSlider, findprop(hSlider, 'Value'), 'PropertyPostSet', @(~, ~)update_label());
        setappdata(hSlider, 'sliderListener', hListener);
        
        set(text, 'String', 'Subimage selection phase.');
    end

    % Save processed image.
    function [] = save_image()
        [path, name, ext] = fileparts(infile);
        default_name = sprintf('%s%s_new%s', path, name, ext);
        [outfile, outpath] = uiputfile(default_name);
        imwrite(r, strcat(outpath, outfile));
    end

    % Subimaging button control functions.
    function [] = update_label()
        %get(controls(3), 'Value')
        % Change continuous to discrete value.
        set(controls(2), 'Value', round(get(controls(2), 'Value')));
        % Update slider label text.
        set(controls(3), 'String', sprintf('Iterations: %d', get(controls(2), 'Value')));
    end

    function [] = new_subimages(h, ~)
        set(h, 'Enable', 'off');  % Don't allow selection during selection.
        
        % Inform the user.
        set(text, 'String', 'Select the repair subimage, double click the rectangle to finish.');
        % Function to keep the rectangle from going oob.
        fcn = makeConstrainToRectFcn('imrect', [1 size(r, 2)], [1 size(r, 1)]);
        rect = imrect('PositionConstraintFcn', fcn);  % Rectangle to use for marking subimages.
        pos_repair = floor(wait(rect));  % Wait for user to select the subimage.
        if isempty(pos_repair)  % Meaning the program is exiting.
            return
        end
        rect.setPosition(pos_repair);  % Set discretized rectangle as position.
        
        % Inform user of second selection.
        set(text, 'String', 'Select the sample subimage, double click the rectangle to finish.');
        % Reuse the rectangle, but don't allow resizing.
        rect.setColor([0.0 1.0 0.0]);  % Change rectangle color, to notify the use that something has changed.
        rect.setResizable(false);  % Subimages have to be the same size, don't allow resizing.
        pos_sample = wait(rect);  % Wait for user to select the subimage.
        if isempty(pos_sample)  % Meaning the program is exiting.
            return
        end
        delete(rect);  % Remove selection rectangle.
        
        % Reset info text.
        set(text, 'String', 'Subimage selection phase.');
        pos_sample(1:2) = floor(pos_sample(1:2));  % Discritize sample x and y.
        
        % Apply restoration algorithm, selectable through a popup menu.
        switch get(controls(5), 'Value')
            case 1
                r = base_algorithm(r, pos_sample, pos_repair, noise_mask, get(controls(2), 'Value'));
            case 2
                r = soft_scratch(r, pos_sample, pos_repair, noise_mask, get(controls(2), 'Value'));
            case 3
                r = split_frequency(r, pos_sample, pos_repair, noise_mask, get(controls(2), 'Value'));                
        end
        imshow(r);
        
        set(h, 'Enable', 'on');  % Re-enable new selection during selection.
    end
end