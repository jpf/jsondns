# 
# domain.rb
#    A class to check domain names for RFC compliance - incomplete.
#
# Copyright 2009 Joel Franusic
# 
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
# 
#        http://www.apache.org/licenses/LICENSE-2.0
# 
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#
class Domain
  attr_reader :name
  def initialize(name)
    name ||= ''
    @name = name
    @labels = name.split(/\./)
    @tld = @labels.last
  end
  def valid?
    # Reference
    #   RFC 1034 Section 3.1
    #   http://tools.ietf.org/html/rfc1034
    #   RFC 3696, Section 2:
    #   http://tools.ietf.org/html/rfc3696#section-2

    return false if @name.empty?

    # [RFC 3696] Return false if the name contains any characters other than /[0-9a-zA-Z\-\.]/
    return false unless @name =~ /^[0-9a-zA-Z\-\.]+$/

    # [RFC 3696] Return false if the name has no "dots"
    return false unless @name.include? '.'

    # [RFC 1034] Return false if the name is longer than 255 octets 
    return false if @name.length > 255

    # [RFC 3696] Return false if the tld is all numeric
    return false if @tld =~ /^[0-9]+$/

    # [RFC 3696] Return false if of any label in the name is longer than 63 octets
    @labels.each { |label| return false if label.length > 63 }

    # [RFC 3696] Return false if the name starts or ends with '-'
    return false if @name[0] == 45 or @name[-1] == 45 # 45 is the character code for '-'

    return true # all tests passed
  end
end # Domain
