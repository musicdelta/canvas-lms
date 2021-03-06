#
# Copyright (C) 2011 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')
require 'lib/stats'

describe Stats do
  context Stats::Counter do
    def check_stats_with_matchers(c, empty, size, max, min, sum, mean, var, stddev, histogram)
      c.empty?.should empty
      c.size.should size
      c.count.should size
      c.max.should max
      c.min.should min
      c.sum.should sum
      c.total.should sum
      c.mean.should mean
      c.avg.should mean
      c.var.should var
      c.variance.should var
      c.stddev.should stddev
      c.standard_deviation.should stddev
      c.histogram.should histogram
    end

    def check_stats(c, size, max, min, sum, mean, var, histogram)
      check_stats_with_matchers c,
                                (size > 0 ? be_false : be_true),
                                eql(size),
                                eql(max),
                                eql(min),
                                eql(sum),
                                be_close(mean, 0.0000000001),
                                be_close(var, 0.0000000001),
                                be_close(Math::sqrt(var), 0.0000000001),
                                eql(histogram)
    end

    it "should be able to initialize with an array" do
      lambda{Stats::Counter.new([1,2,4,6,9])}.should_not raise_error
    end
    
    it "should return some basic statistics" do
      c = Stats::Counter.new([1,2,4,9])
      check_stats(c, 4, 9, 1, 16, 4.0, 9.5, {:bin_width => 1.0, :bin_base => 0.0, :data =>{1.0=>1,2.0=>1,4.0=>1,9.0=>1}})
      c << 6
      check_stats(c, 5, 9, 1, 22, 4.4, 8.24, {:bin_width => 1.0, :bin_base => 0.0, :data =>{1.0=>1,2.0=>1,4.0=>1,9.0=>1,6.0=>1}})
      c << -1
      check_stats(c, 6, 9, -1, 21, 3.5, 139.0/6 - 12.25, {:bin_width => 1.0, :bin_base => 0.0, :data =>{1.0=>1,2.0=>1,4.0=>1,9.0=>1,6.0=>1,-1.0=>1}})
      c << 3
      check_stats(c, 7, 9, -1, 24, 24.0/7, 148.0/7 - 576.0/49, {:bin_width => 1.0, :bin_base => 0.0, :data =>{1.0=>1,2.0=>1,4.0=>1,9.0=>1,6.0=>1,-1.0=>1,3.0=>1}})
      c << 21
      check_stats(c, 8, 21, -1, 45, 5.625, 41.984375, {:bin_width => 1.0, :bin_base => 0.0, :data =>{1.0=>1,2.0=>1,4.0=>1,9.0=>1,6.0=>1,-1.0=>1,3.0=>1,21.0=>1}})
    end

    it "should return the right things with no values" do
      c = Stats::Counter.new
      check_stats_with_matchers c,
                                be_true,
                                eql(0),
                                be_nil,
                                be_nil,
                                eql(0),
                                be_nil,
                                be_nil,
                                be_nil,
                                eql({:bin_width => 1.0, :bin_base => 0.0, :data =>{}})
                                
      c << -5
      check_stats(c, 1, -5, -5, -5, -5.0, 0,{:bin_width => 1.0, :bin_base => 0.0, :data =>{-5.0=>1}})
      c << 5
      check_stats(c, 2, 5, -5, 0, 0.0, 25.0,{:bin_width => 1.0, :bin_base => 0.0, :data =>{-5.0=>1,5.0=>1}})
    end

    it "should support .each, .<<, and .push" do
      c = Stats::Counter.new([1,2,3])
      test = []
      c.each { |item| test << item }
      c << 4
      c.push 5
      c.each { |item| test << item }
      test.should == [1,2,3,1,2,3,4,5]
    end
    
    it "should put negative numbers in the proper bin in histograms" do
      c = Stats::Counter.new([-1, -0.5, 0, 0.5, 1])
      h = c.histogram
      h.should == {:bin_width => 1.0, :bin_base => 0.0, :data =>{-1.0=>2, 0.0=>2, 1.0=>1 }}
    end
    
    it "should work with strange bin widths in histogram" do
      c = Stats::Counter.new([-7,-3,0,1,2,3,4,5,6])
      h = c.histogram(bin_width = 2.5, bin_base = 0.0)
      h.should == {:bin_width=>2.5, :bin_base=>0.0, :data=>{0.0=>3, -5.0=>1, 5.0=>2, -7.5=>1, 2.5=>2}}
    end
    
    it "should work with strange bin bases in histogram" do
      c = Stats::Counter.new([-7,-3,0,1,2,3,4,5,6])
      h = c.histogram(bin_width = 2.5, bin_base = 1.5)
      h.should == {:bin_width=>2.5, :bin_base=>1.5, :data=>{1.5=>2, 4.0=>3, -3.5=>1, -8.5=>1, -1.0=>2}}
    end
    
  end
end
