package hello_test

import (
	"fmt"
	. "github.com/onsi/ginkgo/v2"
)

var _ = Describe("hello test", Label("hello-test"), func() {
	Context("hello test", func() {
		BeforeEach(func() {
			fmt.Println("BeforeEach")
		})
		AfterEach(func() {
			fmt.Println("AfterEach")
		})
	})

	It("hello test 1", Label("hello-test-1"), func() {
	})
})
