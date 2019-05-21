
require "matrix"

module SolveLiner
	module_function
	
	# "1a+2b=3, 2a=3b+4"
	# TODO 不定・不能方程式
	# TODO a,b,c,...#
	# 戻り値は[左辺の行列, 右辺のベクトル]
	def parse(text)
		lmat = []
		rvec = []
		vars = []
		text
			.gsub(/\s+/){""}
			.split(",")
			.map do |eqtext|
				l, r = eqtext.split("=")
				# a+2b -> {"a": 1, "b": 2}
				ls = l
					.split(/(?<=[a-z])/)
					.map do |i|
						s, n, v = i
							.match(/(\+|-)?(\d+|\d+\/\d+|\d+\.\d+)?([a-z])/)
							.captures
						[v, ((s||"")+"1").to_i * (n||"1").to_r]
					end
					.to_h
				vars |= ls.keys
				lmat << vars.map{|v|ls[v]}
				rvec << r.to_r
			end
		{
			a: Matrix[*(lmat.map{|m|vars.map.with_index{|v,vi|m[vi] || Rational(0)}})],
			b: Vector[*rvec],
			vars: vars,
		}
	end
	
	# aは26列ある各変数の係数
	# bはイコールの右辺
	# ( 1, 2 ) (a) = (3)
	# ( 2, 3 ) (b)   (4)
	def solve(a, b)
		size = [a.row_count, a.column_count].max
		ex_a = Matrix[*size.times.map{|i|size.times.map{|j|a[i,j] || Rational(0)}}]
		return "解けないっぽいー？" unless ex_a.regular?
		ex_a.inv * b
	end
	
	def to_s(r, vars)
		h = vars
			.map.with_index{|v,i|[v, r[i]]}
			.to_h
		sv = h.keys.sort
		"(#{sv.join(", ")}) = (#{sv.map{|v|n = h[v]; (n == n.to_i)? n.to_i : n}.join(", ")})"
	end
end
