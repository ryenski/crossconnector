#!/usr/bin/ruby

require 'test/unit'
require 'lib/sparklines'

class SparklinesTest < Test::Unit::TestCase

  def setup
    @output_dir = "test/output"
    @data = %w( 1 5 15 20 30 50 57 58 55 48 
                44 43 42 42 46 48 49 53 55 59
                60 65 75 90 105 106 107 110 115 120
                115 120 130 140 150 160 170 100 100 10).map {|i| i.to_f}
  end

  def test_each_graph
    %w{pie area discrete smooth bar}.each do |type|
    	quick_graph("#{type}", :type => type)
    end
  end

  def test_each_graph_with_label
    %w{pie area discrete smooth bar}.each do |type|
    	quick_graph("labeled_#{type}", :type => type, :label => 'Glucose')
    end
  end

  def test_whisker_random
    # Need data ranging from -2 to +2
    @data = (1..40).map { |i| rand(3) * (rand(2) == 1 ? -1 : 1) }
    quick_graph("whisker", :type => 'whisker')
  end

  def test_whisker_non_exceptional
    @data = [1,1,1,1,1,1,1,1,1,1,1,1,1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1]
    quick_graph("whisker_non_exceptional", :type => 'whisker')
  end

  ##
  # Send random values in the range (-9..9)
  
  def test_whisker_junk
    @data = (1..40).map { |i| rand(10) * (rand(2) == 1 ? -1 : 1) }
    quick_graph("whisker_junk", :type => 'whisker')
  end

  def test_pie
    # Test extremes which previously did not work right
    [0, 1, 45, 95, 99, 100].each do |value|
    	Sparklines.plot_to_file("#{@output_dir}/pie#{value}.png", 
    	                        value, 
    	                        :type => 'pie', 
    	                        :diameter => 128)
    end
    Sparklines.plot_to_file("#{@output_dir}/pie_flat.png", 
                            [60], 
                            :type => 'pie')
  end
  
  def test_special_conditions
    tests = {	'smooth_colored' => {	
                :type => 'smooth', 
                :line_color => 'purple'
                },
    		      'pie_large'	 => {	
    		        :type => 'pie', 
    		        :diameter => 200 
    		        },
    		      'area_high'	 => {	
    		        :type => 'area',
    					  :upper => 80,
                :step => 4,
    					  :height => 20
    					  },
    					'discrete_wide' => { 
    					  :type => 'discrete',
    					  :step => 8 
    					  },
    					'bar_wide' => { 
    					  :type => 'bar',
    					  :step => 8 
    					  },
    					'bar_tall' => {
      					:type => 'bar', 
                :below_color => 'blue', 
                :above_color => 'red',
                :upper => 90, 
                :height => 50,
                :step => 8 
    					  }
    	}
    tests.each do |name, options|
    	quick_graph(name, options)
    end
  end
  
#   def test_smooth_graph
#     
#   end
  
  def test_bar_extreme_values
    Sparklines.plot_to_file("#{@output_dir}/bar_extreme_values.png", 
                            [0,1,100,2,99,3,98,4,97,5,96,6,95,7,94,8,93,9,92,10,91], 
                            :type => 'bar', 
                            :below_color => 'blue', 
                            :above_color => 'red',
                            :upper => 90, 
                            :step => 4 )                              
  end
  
  def test_string_args
    quick_graph("bar_string.png",
                'type' => 'bar', 
                'below_color' => 'blue', 
                'above_color' => 'red',
                'upper' => 50, 
                'height' => 50,
                'step' => 8 )
  end

  def test_area_min_max
    quick_graph("area_min_max", 
                :has_min => true, 
                :has_max => true,
                :has_first => true,
                :has_last => true)
  end
  

  def test_no_type
    Sparklines.plot_to_file("#{@output_dir}/error.png", 0, :type => 'nonexistent')
  end

private

  def quick_graph(name, options)
    Sparklines.plot_to_file("#{@output_dir}/#{name}.png", @data, options)
  end

end
